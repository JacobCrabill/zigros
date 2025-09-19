#include "cli.h"

#include <rclcpp/rclcpp.hpp>

#include <dynmsg/message_reading.hpp>
#include <dynmsg/msg_parser.hpp>
#include <dynmsg/typesupport.hpp>
#include <dynmsg_demo/cli.hpp>
#include <dynmsg_demo/typesupport_utils.hpp>

#include <rcl/context.h>
#include <rcl/error_handling.h>
#include <rcl/graph.h>
#include <rcl/init_options.h>
#include <rcl/node.h>
#include <rcl/node_options.h>
#include <rcl/rcl.h>
#include <rcl/subscription.h>
#include <rcl/types.h>
#include <rcl_action/graph.h>
#include <rcutils/logging_macros.h>

#include <stdint.h>
#include <unistd.h>

#include "topic_rate_monitor.hpp"

static constexpr uint64_t ROS2_DISCOVERY_DELAY_MS = 1000;

void list_nodes()
{
  rclcpp::init(0, NULL);
  rclcpp::Node::SharedPtr node = rclcpp::Node::make_shared("ros2");

  // Note: The discovery process in DDS takes some time, so after creating a brand-new node,
  // we must give it some time to perform discovery.
  // Note: Zenoh does not have this problem.
  rclcpp::sleep_for(std::chrono::milliseconds(ROS2_DISCOVERY_DELAY_MS));

  const std::vector<std::string> nodes = node->get_node_names();

  for (const auto& node : nodes)
  {
    std::cout << node << std::endl;
  }

  rclcpp::shutdown();
}

void list_topics()
{
  rclcpp::init(0, NULL);

  rclcpp::Node::SharedPtr node = rclcpp::Node::make_shared("ros2");

  // Note: The discovery process takes some time, so after creating a brand-new node,
  // we must give it some time to perform discovery.
  rclcpp::sleep_for(std::chrono::milliseconds(ROS2_DISCOVERY_DELAY_MS));

  const std::map<std::string, std::vector<std::string>> topics_and_types = node->get_topic_names_and_types();

  std::cout << "Topics:" << std::endl;
  for (const auto& entry : topics_and_types)
  {
    std::cout << entry.first;
    for (const auto& topic_type : entry.second)
      std::cout << " [" << topic_type << "]";
    std::cout << std::endl;
  }

  rclcpp::shutdown();
}

void list_services()
{
  rclcpp::init(0, NULL);
  rclcpp::Node::SharedPtr node = rclcpp::Node::make_shared("list_services");

  // Note: The discovery process takes some time, so after creating a brand-new node,
  // we must give it some time to perform discovery.
  rclcpp::sleep_for(std::chrono::milliseconds(ROS2_DISCOVERY_DELAY_MS));

  const std::map<std::string, std::vector<std::string>> topics_and_types = node->get_service_names_and_types();

  for (const auto& entry : topics_and_types)
  {
    std::cout << "Service: '" << entry.first << "', Type:";
    for (const auto& topic_type : entry.second)
    {
      std::cout << " '" << topic_type << "'";
    }
    std::cout << std::endl;
  }

  rclcpp::shutdown();
}

/// Read one message from a topic, convert it to YAML, and print it to the terminal.
///
/// This function will look up the topic via the ROS graph information to find the interface type.
/// It then loads the type support and introspection information. The type support is used to
/// subscribe to the topic and wait for a message. Upon reception of a message, the introspection
/// library is used to read the binary data and convert it to a YAML representation.
void echo_topic(const char* topic, uint64_t count)
{
  rclcpp::init(0, NULL);
  rclcpp::Node::SharedPtr node = rclcpp::Node::make_shared("ros2");
  rcl_node_t* node_t = node->get_node_base_interface()->get_rcl_node_handle();

  // Note: The discovery process in DDS takes some time, so after creating a brand-new node,
  // we must give it some time to perform discovery.
  // Note: Zenoh does not have this problem.
  rclcpp::sleep_for(std::chrono::milliseconds(ROS2_DISCOVERY_DELAY_MS));

  InterfaceTypeName interface_type = get_topic_type(node_t, topic);
  if (interface_type.first == "" || interface_type.second == "")
  {
    RCUTILS_LOG_WARN_NAMED("ros2", "Unkonwn topic type '%s/%s'", interface_type.first.c_str(),
                           interface_type.second.c_str());
    return;
  }

  RCUTILS_LOG_DEBUG_NAMED("ros2", "Waiting for message on topic '%s' with type %s/%s", topic,
                          interface_type.first.c_str(), interface_type.second.c_str());

  RosMessage message;
  if (DYNMSG_RET_OK != dynmsg::c::ros_message_init(interface_type, &message))
  {
    RCUTILS_LOG_ERROR_NAMED("ros2", "Message init failed");
    return;
  }

  RCUTILS_LOG_DEBUG_NAMED("ros2", "Finding Type Support");
  const auto* type_support = get_type_support(interface_type);
  if (type_support == nullptr)
  {
    RCUTILS_LOG_WARN_NAMED("ros2", "Couldn't find typesupport handle for topic");
    return;
  }

  RCUTILS_LOG_DEBUG_NAMED("ros2", "Creating subscription");
  rcl_subscription_t sub = rcl_get_zero_initialized_subscription();
  rcl_subscription_options_t sub_options = rcl_subscription_get_default_options();
  auto ret = rcl_subscription_init(&sub, node_t, type_support, topic, &sub_options);
  if (ret != RCL_RET_OK)
  {
    RCUTILS_LOG_ERROR_NAMED("ros2", "subscription init failed");
    return;
  }

  // Ensure a publisher exists for the topic
  while (true)
  {
    size_t pub_count{0};
    ret = rmw_subscription_count_matched_publishers(rcl_subscription_get_rmw_handle(&sub), &pub_count);
    if (ret != RCL_RET_OK)
    {
      RCUTILS_LOG_ERROR_NAMED("ros2", "publisher count failed");
      return;
    }
    RCUTILS_LOG_DEBUG_NAMED("ros2", "There are %ld matched publishers", pub_count);
    if (pub_count > 0)
    {
      break;
    }
    usleep(250'000);
  }

  // Subscribe to the toic and read <count> publications
  size_t rx_count = 0;
  while (true)
  {
    bool taken = false;
    ret = rmw_take(rcl_subscription_get_rmw_handle(&sub), message.data, &taken, nullptr);
    if (ret != RCL_RET_OK)
    {
      RCUTILS_LOG_ERROR_NAMED("ros2", "take failed");
      return;
    }
    if (taken)
    {
      RCUTILS_LOG_DEBUG_NAMED("ros2", "Received data");
      rx_count++;

      std::cout << "--------" << std::endl << dynmsg::c::message_to_yaml(message) << '\n';

      if (count > 0 and rx_count >= count)
        break;
    }
  }

  ret = rcl_subscription_fini(&sub, node_t);

  if (ret != RCL_RET_OK)
  {
    RCUTILS_LOG_ERROR_NAMED("ros2", "subscription fini failed");
    return;
  }

  rclcpp::shutdown();
}

/// Monitor the publication rate of the given topic
///
/// We use a custom node here in order to have two main activities running in parallel:
/// the topic publication count, and a periodic timer to display topic statistics.
void hz_topic(const char* topic)
{
  rclcpp::init(0, NULL);
  auto node = std::make_shared<TopicRateMonitor>(topic);
  rclcpp::spin(node);
  rclcpp::shutdown();
}

// Write the given ROS message (in YAML representation) to the specified topic.
//
// This function requires the interface type be specified, because the topic may not exist until it
// starts publishing data.
//
// This function will load the type support and introspection information for the provided
// interface type. It then converts the given YAML representation into a binary ROS message and
// stores it in a byte buffer. The type support is used to create a publisher to the given topic
// with the correct type, and then the ROS message is published to that topic ten times.
void publish_topic(const char* topic, const char* package_name, const char* type_name, const char* message_yaml,
                   uint64_t count)
{
  rclcpp::init(0, NULL);
  rclcpp::Node::SharedPtr node = rclcpp::Node::make_shared("ros2");
  rcl_node_t* node_t = node->get_node_base_interface()->get_rcl_node_handle();

  // InterfaceTypeName interface_type = get_topic_type(node_t, topic);
  const InterfaceTypeName interface_type =
    std::make_pair<std::string, std::string>(std::string(package_name), std::string(type_name));
  if (interface_type.first == "" || interface_type.second == "")
  {
    RCUTILS_LOG_WARN_NAMED("ros2", "Unkonwn topic type '%s/%s'", interface_type.first.c_str(),
                           interface_type.second.c_str());
    return;
  }

  RCUTILS_LOG_DEBUG_NAMED("ros2", "Publishing message on topic '%s' with type '%s/%s'", topic,
                          interface_type.first.c_str(), interface_type.second.c_str());

  RosMessage message = dynmsg::c::yaml_to_rosmsg(interface_type, message_yaml);

  RCUTILS_LOG_DEBUG_NAMED("ros2", "Creating publisher");

  rcl_publisher_t pub = rcl_get_zero_initialized_publisher();
  rcl_publisher_options_t pub_options = rcl_publisher_get_default_options();
  const auto* type_support = get_type_support(interface_type);
  if (type_support == nullptr)
  {
    return;
  }
  auto ret = rcl_publisher_init(&pub, node_t, type_support, topic, &pub_options);
  if (ret != RCL_RET_OK)
  {
    RCUTILS_LOG_ERROR_NAMED("ros2", "subscription init failed");
    return;
  }

  std::cout << "Publishing\n";
  for (uint64_t ii = 0; ii < count; ++ii)
  {
    ret = rcl_publish(&pub, message.data, nullptr);
    if (ret != RCL_RET_OK)
    {
      RCUTILS_LOG_ERROR_NAMED("ros2", "failed to publish message");
      return;
    }
    sleep(1);
  }

  ret = rcl_publisher_fini(&pub, node_t);
  if (ret != RCL_RET_OK)
  {
    RCUTILS_LOG_ERROR_NAMED("ros2", "publisher fini failed");
    return;
  }

  rclcpp::shutdown();
}

// Print all known actions from the ROS graph to the terminal.
//
// Only actions known about at the time this function is called will be printed. It is recommended
// that some time be allowed to elapse (e.g. by calling a sleep) between calling rcl_init() and
// this function. This gives the underlying discovery system some time to find actions.
void list_actions()
{
  rclcpp::init(0, NULL);
  rclcpp::Node::SharedPtr node = rclcpp::Node::make_shared("ros2");
  rcl_node_t* node_t = node->get_node_base_interface()->get_rcl_node_handle();

  auto actions = rcl_get_zero_initialized_names_and_types();
  auto allocator = rcl_get_default_allocator();
  auto ret = rcl_action_get_names_and_types(node_t, &allocator, &actions);
  if (ret != RCL_RET_OK)
  {
    RCUTILS_LOG_ERROR_NAMED("ros2", "%s", rcl_get_error_string().str);
    return;
  }
  std::cout << "actions:" << std::endl;
  for (size_t i = 0; i < actions.names.size; i++)
  {
    std::cout << "  " << actions.names.data[i] << " [" << actions.types[i].data[0] << "]" << std::endl;
  }
  ret = rcl_names_and_types_fini(&actions);
  if (ret != RCL_RET_OK)
  {
    RCUTILS_LOG_ERROR_NAMED("ros2", "%s", rcl_get_error_string().str);
    return;
  }

  rclcpp::shutdown();
}
