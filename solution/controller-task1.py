#!/usr/bin/env python3
# Copyright 2019 Belma Turkovic
# TU Delft Embedded and Networked Systems Group.
# NOTICE: THIS FILE IS BASED ON https://github.com/p4lang/tutorials/tree/master/exercises/p4runtime, BUT WAS MODIFIED UNDER COMPLIANCE
# WITH THE APACHE 2.0 LICENCE FROM THE ORIGINAL WORK.

# Import P4Runtime lib from parent utils dir
# Probably there's a better way of doing this.

from tokenize import String
import util.lib.p4_cli.bmv2 as bmv2
from util.lib.p4_cli.switch import ShutdownAllSwitchConnections
from util.lib.p4_cli.convert import encodeNum
import util.lib.p4_cli.helper as helper
from scapy.all import (
    Ether,
)
from time import sleep
import sys
import os
import grpc
import argparse
import json

sys.path.append(os.path.join(os.path.dirname(
    os.path.abspath(__file__)), "./util/"))
sys.path.append(os.path.join(os.path.dirname(
    os.path.abspath(__file__)), "./util/lib/"))


# Scappy imports to support packet parsing.


def printGrpcError(e):
    print("gRPC Error:", e.details(), end="")
    status_code = e.code()
    print("(%s)" % status_code.name, end="")
    traceback = sys.exc_info()[2]
    print("[%s:%d]" % (traceback.tb_frame.f_code.co_filename, traceback.tb_lineno))


def main(p4info_file_path: str, bmv2_file_path: str, runtime_conf: str) -> None:
    # Instantiate a P4Runtime helper from the p4info file. This allows you to convert table and field names into integers which make sense for the GRPC API.
    p4info_helper = helper.P4InfoHelper(p4info_file_path)

    try:
        # Load s1-runtime.json  configuration file
        conf = json.load(open(runtime_conf))

        # Create a switch connection object for s1;
        # this is backed by a P4Runtime gRPC connection.
        # Also, dump all P4Runtime messages sent to switch to given txt files.
        s1 = bmv2.Bmv2SwitchConnection(
            name="s1",
            address="127.0.0.1:50001",
            device_id=1,
            proto_dump_file="p4runtime.log",
        )

        # Step 1: Establish gRPC connection and set master arbitration update
        # This step establishes this controller as
        # master (required by P4Runtime before performing any other write operation)
        MasterArbitrationUpdate = s1.MasterArbitrationUpdate()
        print(MasterArbitrationUpdate)
        if MasterArbitrationUpdate == None:
            print("Failed to establish the connection")

        # Step 2: Install the P4 program on the switches
        try:
            s1.SetForwardingPipelineConfig(
                p4info=p4info_helper.p4info, bmv2_json_file_path=bmv2_file_path
            )
            print("Installed P4 Program using SetForwardingPipelineConfig on s1")
        except Exception as e:
            print("Forwarding Pipeline added.")
            print(e)
            # Forward all packet to the controller (CPU_PORT 255)

        # Step 3: Write Multicast Group Entries
        if "multicast_group_entries" in conf:
            for mc_group in conf["multicast_group_entries"]:
                mc_group_id = mc_group["multicast_group_id"]
                replicas = mc_group["replicas"]
                entry = p4info_helper.buildMCEntry(
                    mc_group_id, replicas
                )
                s1.WritePREEntry(entry)
                print(
                    "Installed Multicast Group Entry on s1 with ID %d %s" % (
                        mc_group_id, replicas)
                )

        while True:
            sleep(1)

    except KeyboardInterrupt:
        print(" Shutting down.")
    except grpc.RpcError as e:
        printGrpcError(e)

    ShutdownAllSwitchConnections()


if __name__ == "__main__":
    parser = argparse.ArgumentParser(description="P4Runtime Controller")
    parser.add_argument(
        "--p4info",
        help="p4info proto in text format from p4c",
        type=str,
        action="store",
        required=False,
        default="./p4src/build/p4info.txt",
    )
    parser.add_argument(
        "--bmv2-json",
        help="BMv2 JSON file from p4c",
        type=str,
        action="store",
        required=False,
        default="./p4src/build/main.json",
    )
    args = parser.parse_args()

    if not os.path.exists(args.p4info):
        parser.print_help()
        print("\np4info file %s not found!" % args.p4info)
        parser.exit(1)
    if not os.path.exists(args.bmv2_json):
        parser.print_help()
        print("\nBMv2 JSON file %s not found!" % args.bmv2_json)
        parser.exit(2)
    main(args.p4info, args.bmv2_json, "mininet/s1-runtime.json")
