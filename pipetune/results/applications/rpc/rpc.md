Status: Incomplete

Date: 10/04/2023

Ref:
1. [eRPC](https://github.com/erpc-io/eRPC)

## Goals
Test the end-to-end performance (throughput and latency) of raw eRPC systems. 

## Running eRPC
To run an eRPC application, modify the scripts/autorun_app_file, which decide the application running in this round (e.g., 'latency' indicates that apps/latency is going to run). Next, create an autorun_process_file to configure servers involved in the eRPC application. Finally, run script/do.sh to start.

To configure specific applications, modify the 'config' file located in apps/app_name.