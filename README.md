# Origin

In a multiarch openshift cluster, adding an ARM64 machineset to a x86 cluster is a day-2 operation.

The information for 4.16 is in [this article](https://docs.openshift.com/container-platform/4.16/post_installation_configuration/configuring-multi-arch-compute-machines/creating-multi-arch-compute-nodes-azure.html). However, it is made of manual tasks that is error prone. Additionally, it sugests to use new storage objects instead of reusing the existing ones. 

This repo contains an example to query for the existing objects, create the new aarch64 ones and new machinesets with all those information in a clean and simple way.

It is not an extensive solution, it may not cover all the possible configurations, but can be customized easily to achieve the goal.

