#pragma once

#include <chrono>
#include <iostream>
#include <memory>
#include <mutex>

#include <rclcpp/rclcpp.hpp>
#include <rclcpp/subscription_options.hpp>
#include <rclcpp/serialization.hpp>

namespace {

rclcpp::QoS adapt_request_to_offers(const std::string& topic_name,
                                    const std::vector<rclcpp::TopicEndpointInfo>& endpoints)
{
  if (endpoints.empty())
  {
    return rclcpp::QoS(rmw_qos_profile_default.depth);
  }
  size_t num_endpoints = endpoints.size();
  size_t reliability_reliable_endpoints_count = 0;
  size_t durability_transient_local_endpoints_count = 0;
  size_t max_history_depth = 0;
  for (const auto& endpoint : endpoints)
  {
    const auto& profile = endpoint.qos_profile().get_rmw_qos_profile();
    if (profile.reliability == RMW_QOS_POLICY_RELIABILITY_RELIABLE)
    {
      reliability_reliable_endpoints_count++;
    }
    if (profile.durability == RMW_QOS_POLICY_DURABILITY_TRANSIENT_LOCAL)
    {
      durability_transient_local_endpoints_count++;
    }
    if (profile.depth > max_history_depth)
    {
      max_history_depth = profile.depth;
    }
  }

  // We set policies in order as defined in rmw_qos_profile_t
  rclcpp::QoS request_qos(rmw_qos_profile_default.depth);
  // Policy: history, depth
  // History does not affect compatibility. However, it could affect messages drop on the DDS side.
  if (max_history_depth > 1)
  {
    request_qos.keep_last(max_history_depth);
  } else
  {
    if (max_history_depth == 1)
    {
      RCUTILS_LOG_DEBUG_NAMED("ros2",
                              "Publishers on topic \"%s\" are offering "
                              "RMW_QOS_POLICY_HISTORY_KEEP_LAST with depth = 1. There is a high probability that "
                              "messages will be dropped. Falling back to the RMW_QOS_POLICY_HISTORY_KEEP_ALL.",
                              topic_name.c_str());
    }
    request_qos.keep_all();
  }

  // Policy: reliability
  if (reliability_reliable_endpoints_count == num_endpoints)
  {
    request_qos.reliable();
  } else
  {
    if (reliability_reliable_endpoints_count > 0)
    {
      RCUTILS_LOG_WARN_NAMED("ros2",
                             "Some, but not all, publishers on topic \"%s\" "
                             "are offering RMW_QOS_POLICY_RELIABILITY_RELIABLE. "
                             "Falling back to RMW_QOS_POLICY_RELIABILITY_BEST_EFFORT "
                             "as it will connect to all publishers. "
                             "Some messages from Reliable publishers could be dropped.",
                             topic_name.c_str());
    }
    request_qos.best_effort();
  }

  // Policy: durability
  // If all publishers offer transient_local, we can request it and receive latched messages
  if (durability_transient_local_endpoints_count == num_endpoints)
  {
    request_qos.transient_local();
  } else
  {
    if (durability_transient_local_endpoints_count > 0)
    {
      RCUTILS_LOG_WARN_NAMED("ros2",
                             "Some, but not all, publishers on topic \"%s\" "
                             "are offering RMW_QOS_POLICY_DURABILITY_TRANSIENT_LOCAL. "
                             "Falling back to RMW_QOS_POLICY_DURABILITY_VOLATILE "
                             "as it will connect to all publishers. "
                             "Previously-published latched messages will not be retrieved.",
                             topic_name.c_str());
    }
    request_qos.durability_volatile();
  }
  // Policy: deadline
  // Deadline does not affect delivery of messages,
  // and we do not record Deadline"Missed events.
  // We can always use unspecified deadline, which will be compatible with all publishers.

  // Policy: lifespan
  // Lifespan does not affect compatibiliy

  // Policy: liveliness, liveliness_lease_duration
  // Liveliness does not affect delivery of messages,
  // and we do not record LivelinessChanged events.
  // We can always use unspecified liveliness, which will be compatible with all publishers.
  return request_qos;
}

std::optional<rclcpp::TopicEndpointInfo> getTopicInfo(const rclcpp::Node* node, const std::string& topic)
{
  const std::vector<rclcpp::TopicEndpointInfo> endpoint_infos = node->get_publishers_info_by_topic(topic);

  if (endpoint_infos.empty())
    return std::nullopt;

  // Just return the first listed publisher for simplicity
  rclcpp::TopicEndpointInfo topic_info = endpoint_infos.front();

  // Correct the rclcpp::QoS value to be valid
  topic_info.qos_profile() = adapt_request_to_offers(topic, endpoint_infos);

  return topic_info;
}

std::shared_ptr<rclcpp::SubscriptionBase>
createGenericSubscriber(rclcpp::Node* node, const std::string& topic,
                        std::function<void(std::shared_ptr<rclcpp::SerializedMessage>)> callback)
{
  const auto topic_opt = getTopicInfo(node, topic);
  if (!topic_opt)
  {
    RCLCPP_ERROR_STREAM(node->get_logger(), "Required topic is not yet published: '" << topic << "'");
    return nullptr;
  }
  const rclcpp::TopicEndpointInfo& topic_info = topic_opt.value();

  auto subscription =
    node->create_generic_subscription(topic, topic_info.topic_type(), topic_info.qos_profile(), callback);

  if (subscription)
  {
    RCLCPP_INFO_STREAM(node->get_logger(), "Subscribed to topic '" << topic << "'");
  } else
  {
    RCLCPP_ERROR_STREAM(node->get_logger(), "Unable to subscribe to topic '" << topic << "'");
  }
  return subscription;
}
}

// A generic class to monitor the publication rate of any ROS2 topic.
class TopicRateMonitor : public rclcpp::Node {
 public:
  // The constructor now takes the topic name as a string argument.
  TopicRateMonitor(const std::string& topic_name)
      : rclcpp::Node("topic_rate_monitor"), topic_name_(topic_name)
  {
    // We now use a GenericSubscription to subscribe to any topic type.
    // The callback only cares about the arrival of a message, not its content.
    subscription_ = createGenericSubscriber(this, topic_name,
        [this](std::shared_ptr<rclcpp::SerializedMessage>) { this->topic_callback(); });

    // Create a 1-second timer to print statistics.
    timer_ = create_wall_timer(
        std::chrono::seconds(1),
        std::bind(&TopicRateMonitor::timer_callback, this));

    RCLCPP_INFO(get_logger(), "Monitoring topic '%s'...", topic_name.c_str());
  }

 private:
  // Mutex to protect data from concurrent access by the subscriber and timer callbacks.
  std::mutex mutex_;

  // Member variables to store statistics.
  size_t count_{0};
  size_t window_count_{0};
  double min_time_diff_sec_{1e9};
  double max_time_diff_sec_{0};
  const std::string topic_name_;

  rclcpp::Time start_time_;
  rclcpp::Time last_msg_time_;

  // ROS2 GenericSubscription.
  std::shared_ptr<rclcpp::SubscriptionBase> subscription_;
  rclcpp::TimerBase::SharedPtr timer_;

  // The callback now takes a SerializedMessage, but our logic remains the same
  // as we only care about the event of a message arriving.
  void topic_callback() {
    std::lock_guard<std::mutex> lock(mutex_);
    const auto now = this->now();

    // Handle the very first message.
    if (count_ == 0) {
      start_time_ = now;
    } else {
      // Calculate time difference between messages.
      const double time_diff = (now - last_msg_time_).seconds();
      min_time_diff_sec_ = std::min(min_time_diff_sec_, time_diff);
      max_time_diff_sec_ = std::max(max_time_diff_sec_, time_diff);
    }
    last_msg_time_ = now;
    count_++;
    window_count_++;
  }

  void timer_callback() {
    std::lock_guard<std::mutex> lock(mutex_);

    // Only print statistics if at least one message has been received.
    if (count_ > 0) {
      const auto now = this->now();
      const double total_elapsed = (now - start_time_).seconds();

      // Calculate overall and 1s windowed frequencies.
      const double overall_frequency = static_cast<double>(count_) / total_elapsed;
      const double window_frequency = static_cast<double>(window_count_);
      const size_t min_dt_ms = static_cast<size_t>(min_time_diff_sec_ * 1000);
      const size_t max_dt_ms = static_cast<size_t>(max_time_diff_sec_ * 1000);

      // Print the formatted statistics.
      printf("Rates for topic %s:\n"
             "\tPublication Count: %lu\n"
             "\tOverall Frequency: %.2f Hz\n"
             "\t1s Window Frequency: %.2f Hz\n"
             "\tMin Time Between Messages: %d ms\n"
             "\tMax Time Between Messages: %d ms\n",
             topic_name_.c_str(), count_, overall_frequency, window_frequency, min_dt_ms, max_dt_ms);

      // Reset the window count for the next second.
      window_count_ = 0;
    }
  }
};
