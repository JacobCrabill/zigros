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

#include <unistd.h>

static constexpr uint64_t ROS2_DISCOVERY_DELAY_MS = 1000;

// static rcl_node_t g_node;
// static rcl_context_t g_context;

int initialize_node(rcl_node_t* g_node, rcl_context_t* g_context)
{
  int argc = 1;
  char* argv[] = {"ros2", NULL};

  // Initialise the options for ROS
  rcl_init_options_t options = rcl_get_zero_initialized_init_options();
  rcl_ret_t ret = rcl_init_options_init(&options, rcl_get_default_allocator());
  if (ret != RCL_RET_OK)
  {
    RCUTILS_LOG_ERROR_NAMED("ros2", "init options failed");
    return 1;
  }

  // Initialise ROS itself
  *g_context = rcl_get_zero_initialized_context();
  ret = rcl_init(argc, argv, &options, g_context);
  if (ret != RCL_RET_OK)
  {
    RCUTILS_LOG_ERROR_NAMED("ros2", "init failed");
    return 1;
  }

  ret = rcl_init_options_fini(&options);
  if (ret != RCL_RET_OK)
  {
    RCUTILS_LOG_ERROR_NAMED("ros2", "init_options fini failed");
    return 1;
  }

  // Create a node to get access to the ROS graph, topics, etc.
  RCUTILS_LOG_DEBUG_NAMED("ros2", "Creating node");
  rcl_node_options_t node_options = rcl_node_get_default_options();
  *g_node = rcl_get_zero_initialized_node();
  ret = rcl_node_init(g_node, "clitool", "", g_context, &node_options);
  if (ret != RCL_RET_OK)
  {
    RCUTILS_LOG_ERROR_NAMED("ros2", "node init failed");
    return 1;
  }

  return 0;
}

void deinitialize_node(rcl_node_t* g_node, rcl_context_t* g_context)
{
  // Shut down and clean up
  rcl_ret_t ret = rcl_node_fini(g_node);
  if (ret != RCL_RET_OK)
  {
    RCUTILS_LOG_ERROR_NAMED("ros2", "node fini failed");
    return;
  }
  ret = rcl_shutdown(g_context);
  if (ret != RCL_RET_OK)
  {
    RCUTILS_LOG_ERROR_NAMED("ros2", "shutdown failed");
    return;
  }
  ret = rcl_context_fini(g_context);
  if (ret != RCL_RET_OK)
  {
    RCUTILS_LOG_ERROR_NAMED("ros2", "context fini failed");
    return;
  }
}

void list_nodes()
{
  rclcpp::init(0, NULL);

  rclcpp::Node::SharedPtr node = rclcpp::Node::make_shared("list_topics");

  // Note: The discovery process takes some time, so after creating a brand-new node,
  // we must give it some time to perform discovery.
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

  rclcpp::Node::SharedPtr node = rclcpp::Node::make_shared("list_topics");

  // Note: The discovery process takes some time, so after creating a brand-new node,
  // we must give it some time to perform discovery.
  rclcpp::sleep_for(std::chrono::milliseconds(ROS2_DISCOVERY_DELAY_MS));

  const std::map<std::string, std::vector<std::string>> topics_and_types = node->get_topic_names_and_types();

  for (const auto& entry : topics_and_types)
  {
    std::cout << "Topic: '" << entry.first << "', Type:";
    for (const auto& topic_type : entry.second)
    {
      std::cout << " '" << topic_type << "'";
    }
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
void echo_topic(const char* topic)
{
  std::cout << "Creating node..." << std::endl;
  rcl_node_t g_node;
  rcl_context_t g_context;
  if (initialize_node(&g_node, &g_context) != 0)
  {
    RCUTILS_LOG_ERROR_NAMED("ros2", "Node init failed");
    return;
  }
  std::cout << "Created node" << std::endl;

  InterfaceTypeName interface_type = get_topic_type(&g_node, topic);
  if (interface_type.first == "" || interface_type.second == "")
  {
    std::cout << "Unknown topic type '" << interface_type.first << '/' << interface_type.second << "'\n";
    return;
  }

  std::cout << "Waiting for message on topic '" << topic << "' with type " << interface_type.first << '/'
            << interface_type.second << '\n';

  RosMessage message;
  if (DYNMSG_RET_OK != dynmsg::c::ros_message_init(interface_type, &message))
  {
    RCUTILS_LOG_ERROR_NAMED("ros2", "Message init failed");
    return;
  }

  RCUTILS_LOG_DEBUG_NAMED("ros2", "Creating subscription");
  rcl_subscription_t sub = rcl_get_zero_initialized_subscription();
  rcl_subscription_options_t sub_options = rcl_subscription_get_default_options();
  const auto* type_support = get_type_support(interface_type);
  if (type_support == nullptr)
  {
    return;
  }
  auto ret = rcl_subscription_init(&sub, &g_node, type_support, topic, &sub_options);
  if (ret != RCL_RET_OK)
  {
    RCUTILS_LOG_ERROR_NAMED("ros2", "subscription init failed");
    return;
  }

  while (true)
  {
    size_t count{0};
    ret = rmw_subscription_count_matched_publishers(rcl_subscription_get_rmw_handle(&sub), &count);
    if (ret != RCL_RET_OK)
    {
      RCUTILS_LOG_ERROR_NAMED("ros2", "publisher count failed");
      return;
    }
    RCUTILS_LOG_DEBUG_NAMED("ros2", "There are %ld matched publishers", count);
    if (count > 0)
    {
      break;
    }
    usleep(250'000);
  }

  bool taken = false;
  while (!taken)
  {
    taken = false;
    ret = rmw_take(rcl_subscription_get_rmw_handle(&sub), message.data, &taken, nullptr);
    if (ret != RCL_RET_OK)
    {
      RCUTILS_LOG_ERROR_NAMED("ros2", "take failed");
      return;
    }
    if (taken)
    {
      RCUTILS_LOG_DEBUG_NAMED("ros2", "Received data");
      break;
    }
  }

  std::cout << dynmsg::c::message_to_yaml(message) << '\n';

  ret = rcl_subscription_fini(&sub, &g_node);
  if (ret != RCL_RET_OK)
  {
    RCUTILS_LOG_ERROR_NAMED("ros2", "subscription fini failed");
    return;
  }

  deinitialize_node(&g_node, &g_context);
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
int publish_to_topic(rcl_node_t* node, const std::string& topic, const InterfaceTypeName& interface_type,
                     const std::string& message_yaml)
{
  std::cout << "Publishing message on topic '" << topic << "' with type " << interface_type.first << '/'
            << interface_type.second << '\n';

  RosMessage message = dynmsg::c::yaml_to_rosmsg(interface_type, message_yaml);

  RCUTILS_LOG_DEBUG_NAMED("ros2", "Creating publisher");
  rcl_publisher_t pub = rcl_get_zero_initialized_publisher();
  rcl_publisher_options_t pub_options = rcl_publisher_get_default_options();
  const auto* type_support = get_type_support(interface_type);
  if (type_support == nullptr)
  {
    return 1;
  }
  auto ret = rcl_publisher_init(&pub, node, type_support, topic.c_str(), &pub_options);
  if (ret != RCL_RET_OK)
  {
    RCUTILS_LOG_ERROR_NAMED("ros2", "subscription init failed");
    return 1;
  }

  for (auto ii = 0; ii < 10; ++ii)
  {
    std::cout << "Publishing\n";
    ret = rcl_publish(&pub, message.data, nullptr);
    if (ret != RCL_RET_OK)
    {
      RCUTILS_LOG_ERROR_NAMED("ros2", "failed to publish message");
      return 1;
    }
    sleep(1);
  }

  ret = rcl_publisher_fini(&pub, node);
  if (ret != RCL_RET_OK)
  {
    RCUTILS_LOG_ERROR_NAMED("ros2", "publisher fini failed");
    return 1;
  }
  return 0;
}

// Print all known actions from the ROS graph to the terminal.
//
// Only actions known about at the time this function is called will be printed. It is recommended
// that some time be allowed to elapse (e.g. by calling a sleep) between calling rcl_init() and
// this function. This gives the underlying discovery system some time to find actions.
void print_actions(const rcl_node_t* node)
{
  rcl_node_t g_node;
  rcl_context_t g_context;
  if (initialize_node(&g_node, &g_context) != 0)
  {
    RCUTILS_LOG_ERROR_NAMED("ros2", "Node init failed");
    return;
  }

  auto actions = rcl_get_zero_initialized_names_and_types();
  auto allocator = rcl_get_default_allocator();
  auto ret = rcl_action_get_names_and_types(node, &allocator, &actions);
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

  deinitialize_node(&g_node, &g_context);
}
