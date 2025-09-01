#pragma once

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

void echo_topic(const char* topic_name);

#ifdef __cplusplus
}
#endif
