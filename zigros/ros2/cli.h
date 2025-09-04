#pragma once

#include <stdint.h>

#ifdef __cplusplus
extern "C" {
#endif

/**
 * Print all known nodes from the ROS graph to the terminal.
 *
 * Only nodes known about at the time this function is called will be printed. It is recommended
 * that some time be allowed to elapse (e.g. by calling a sleep) between calling rcl_init() and
 * this function. This gives the underlying discovery system some time to find other nodes.
 */
void list_nodes();

/**
 * Print all known topics from the ROS graph to the terminal.
 *
 * Only topics known about at the time this function is called will be printed. It is recommended
 * that some time be allowed to elapse (e.g. by calling a sleep) between calling rcl_init() and
 * this function. This gives the underlying discovery system some time to find topics.
 */
void list_topics();

/**
 * Print all known services from the ROS graph to the terminal.
 *
 * Only services known about at the time this function is called will be printed. It is recommended
 * that some time be allowed to elapse (e.g. by calling a sleep) between calling rcl_init() and
 * this function. This gives the underlying discovery system some time to find services.
 */
void list_services();

/**
 * Print all known actions from the ROS graph to the terminal.
 *
 * Only actions known about at the time this function is called will be printed. It is recommended
 * that some time be allowed to elapse (e.g. by calling a sleep) between calling rcl_init() and
 * this function. This gives the underlying discovery system some time to find actions.
 */
void list_actions();

/**
 * Subscribe to and print 'count' publications from the given topic name.
 *
 * A 'count' value of 0 means forever.
 *
 * If the topic is not advertised, this will fail. Otherwise, this will block
 * until a publication is made.
 */
void echo_topic(const char* topic_name, uint64_t count);

/**
 * Publish a message on the given topic name.
 *
 * The provided YAML should match the advertised message type.
 *
 * The message should be defined in YAML syntax. The simplest way to provide
 * valid YAML may be to provide it from a file on disk.
 */
void publish_topic(const char* topic_name, const char* package_name, const char* type_name, const char* message_yaml,
                   uint64_t count);

#ifdef __cplusplus
}
#endif
