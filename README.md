# Introduction to the P4Runtime API

In the last lab activity you were introduced to the P4 language and you implement a static P4 Ethernet switch. In this activity you will learn how to implement a P4 controller in Python and implement a basic learning switch. To ease your way into P4 controllers, we will discuss the P4Runtime API, which is used to control P4-programmable switches at runtime. We will use the basic interactions between a P4 controller and a P4-programmable switch to provide an example of how the API works and how to use it. Treat this tutorial as an introduction to GRPC, but not a complete guide. You can find more information about GRPC and Protobuf in the links provided below.

By the end of this activity you will be able to:

- [ ] Understand the P4Runtime API and its components
- [ ] Implement a basic P4 controller using the P4Runtime API
- [ ] Implement a learning switch using P4 and the P4Runtime API

## SDN controllers and Southbound APIs

In Software-Defined Networking (SDN), the control plane is separated from the data plane. The control plane is responsible for making decisions about how packets should be forwarded, while the data plane is responsible for forwarding packets based on the decisions made by the control plane. In the context of P4, the data plane can be defined using the P4 language. Between the control plance and the data plane we typically need an API that allows the control plane to communicate with the data plane devices. This API is called a southbound API.

In our example of a P4 switch, the P4Runtime API is a southbound API that allows a controller to manage and control P4-programmable devices at runtime. The controller then uses the P4Runtime API to install P4 programs, add and remove table entries, and configure switch parameters. In the first lecture of this course, we discussed the OpenFlow protocol, which is an early example of a southbound API. OpenFlow is a widely used southbound API that allows controllers to manage and control network devices. However, OpenFlow is static and assumes that the data plane is fixed and cannot be changed. Nonetheless, the P4 data plane can vary across programs and devices, and thus we need a more flexible southbound API that can adapt to different P4 programs and devices. The P4Runtime API is designed to be flexible and extensible, allowing it to support different P4 programs and devices. To achieve this flexibility, the P4Runtime API is based on gRPC and Protocol Buffers (Protobuf).

## What is GRPC and Protobuf?

A big challenge in distributed computer systems is the design of communication mechanisms between different components. Through the years a number of Remote Procedure Call (RPC) frameworks have been developed to address this challenge. These frameworks allow a program to call procedures (functions) located on another machine as if they were local function calls. They offer languages and platform-neutral interfaces to define the procedures and their parameters, and they handle the underlying communication details. As a result, the developer can define the protocol details once and then a compiler generates the necessary code to handle the communication between different components for different languages and platforms. This make the development of distributed systems much easier and less error-prone. The Google Protocol Buffers (Protobuf) and gRPC are the latest anhat are widely used in the industry.

The protobuf language is a language-neutral, platform-neutral extensible mechanism for serializing structured data. It is used to define the structure of the data that will be exchanged between different components in a distributed system. The protobuf compiler generates code in different languages (e.g., C++, Java, Python) to serialize and deserialize the data. An example of a protobuf definition is shown below:

```protobufd greatest frameworks t
syntax = "proto3";
message Person {
  string name = 1;
  int32 id = 2;
  string email = 3;
}

message PersonRequest {
  int32 id = 1;
}

message PersonResponse {
  bool success = 1;
}
```

You can use this code snippet and the protobuf compiler to generate Python classes to serialize and deserialize the `Person` message in different languages. The P4 language uses protobuf to define the structure of P4 tables and other P4 constructs, and the users can use any language to interact with P4-programmable devices. You can find more information about protobuf [here](https://developers.google.com/protocol-buffers), while the P4 protobuf definitions can be found as part of this repository in ``p4runtime/proto/p4/v1/p4runtime.proto``. Protobuf is primarily designed to describe the strcture of the messages exchanged between different components. However, it does not provide a mechanism for defining the procedures (functions) that will be called remotely. This is where gRPC comes in.

gRPC builts on protobuf to realise a high-performance, open-source universal RPC framework that can run in any environment. It enables client and server applications to communicate transparently, and makes it easier to build connected systems. gRPC uses protobuf to define the structure of the messages exchanged between the client and server, as well as the procedures that can be called remotely. Using this specifications, a developer can build code for any programming language, that allows the to implements client and servers without the need to write the low-level socker code. An example of a gRPC service definition is shown below:

```protobuf
service PersonService {
  rpc GetPerson (PersonRequest) returns (Person);
  rpc CreatePerson (Person) returns (PersonResponse);
}
```

In this scenario, the `PersonService` defines two RPC methods: `GetPerson` and `CreatePerson`. The `GetPerson` method takes a `PersonRequest` message as input and returns a `Person` message as output, while the `CreatePerson` method takes a `Person` message as input and returns a `PersonResponse` message as output. You can use this code snippet and the protobuf compiler to generate Python classes to implement the client and server for the `PersonService`. You can find more information about gRPC [here](https://grpc.io/docs/).

### P4Runtime API Overview

The P4Runtime API is a gRPC-based API that allows a controller to manage and control P4-programmable devices at runtime. The P4Runtime API is defined using Protobuf, and it provides a set of RPC methods that can be used to interact with P4-programmable devices. The P4Runtime API is defined in the `p4runtime.proto` file, which can be found in the `p4runtime/proto/p4/v1/` directory of this repository.

The P4Runtime API provides a set of RPC methods that can be used to perform various operations on P4-programmable devices. The RPC methods of the P4runtime service are defined in the file `proto/p4/v1/p4runtime.proto`  and are shown below:

```protobuf
service P4Runtime {
  // Update one or more P4 entities on the target.
  rpc Write(WriteRequest) returns (WriteResponse) {
  }
  // Read one or more P4 entities from the target.
  rpc Read(ReadRequest) returns (stream ReadResponse) {
  }

  // Sets the P4 forwarding-pipeline config.
  rpc SetForwardingPipelineConfig(SetForwardingPipelineConfigRequest)
      returns (SetForwardingPipelineConfigResponse) {
  }
  // Gets the current P4 forwarding-pipeline config.
  rpc GetForwardingPipelineConfig(GetForwardingPipelineConfigRequest)
      returns (GetForwardingPipelineConfigResponse) {
  }

  // Represents the bidirectional stream between the controller and the
  // switch (initiated by the controller), and is managed for the following
  // purposes:
  // - connection initiation through client arbitration
  // - indicating switch session liveness: the session is live when switch
  //   sends a positive client arbitration update to the controller, and is
  //   considered dead when either the stream breaks or the switch sends a
  //   negative update for client arbitration
  // - the controller sending/receiving packets to/from the switch
  // - streaming of notifications from the switch
  rpc StreamChannel(stream StreamMessageRequest)
      returns (stream StreamMessageResponse) {
  }

  rpc Capabilities(CapabilitiesRequest) returns (CapabilitiesResponse) {
  }
}
```

The `SetForwardingPipelineConfig` RPC method is used to install a P4 program on a P4-programmable device, while the `GetForwardingPipelineConfig` RPC method is used to retrieve the current P4 program installed on a device. You typically used this method upon connecting to a switch to load the P4 program, as generated from the p4c compiler. An example of the data used to load the P4 program can be found in folder `p4src/build/bmv2.json`, but it won't make much understand the details. The P4rutime service defines the `Write` and `Read` RPC methods are used to add, modify, delete, and read different properties of the switch. An exmaple of the properties that can be modified using these methods can be found below. Be aware that these methods are **synchronous**, We will only use a small subset of these properties in this activity.

```protobuf
message Entity {
  oneof entity {
    ExternEntry extern_entry = 1;
    TableEntry table_entry = 2;
    ActionProfileMember action_profile_member = 3;
    ActionProfileGroup action_profile_group = 4;
    MeterEntry meter_entry = 5;
    DirectMeterEntry direct_meter_entry = 6;
    CounterEntry counter_entry = 7;
    DirectCounterEntry direct_counter_entry = 8;
    PacketReplicationEngineEntry packet_replication_engine_entry = 9;
    ValueSetEntry value_set_entry = 10;
    RegisterEntry register_entry = 11;
    DigestEntry digest_entry = 12;
  }
}
```


The `StreamChannel` RPC method is used to establish a bidirectional stream between the controller and the P4-programmable device, which can be used to send and receive packets and notifications. This is used for asynchronous communication between the controller and the switch. For example, the switch can use this call to forward data from the data plane to the controller, usinf the packet-in messages, while the controller can use it to inject packets to the data plane, using  packet-out messages. A list of all the message types used in the P4Runtime API can be found in the `p4runtime.proto` file.

```protobuf
message StreamMessageRequest {
  oneof update {
    MasterArbitrationUpdate arbitration = 1;
    PacketOut packet = 2;
    DigestListAck digest_ack = 3;
    .google.protobuf.Any other = 4;
  }
}

message StreamMessageResponse {
  oneof update {
    MasterArbitrationUpdate arbitration = 1;
    PacketIn packet = 2;
    DigestList digest = 3;
    IdleTimeoutNotification idle_timeout_notification = 4;
    .google.protobuf.Any other = 5;
    // Used by the server to asynchronously report errors which occur when
    // processing StreamMessageRequest messages.
    StreamError error = 6;
  }
}
```

## Task 1: Configure a switch with the P4Runtime API

In the first lab of this module, we revisited how a learning switch works and identified two key functionalities: Flood and MAC learning. Flooding is essential for ensuring that packets reach all possible destinations when the destination MAC address is unknown. MAC learning allows the switch to learn the source MAC addresses of incoming packets and associate them with the corresponding switch ports, enabling efficient forwarding of packets to known destinations.

In this first task, we will extend our P4 static switch and add the ability to flood packets to the switch ports. To achieve this, we will need to use the P4Runtime API to configure a multicast group on the switch. A multicast group is a virtual port, to which we can send a packet using the `standard_metadata.mcast_grp` field in the Ingress block. A controller can add multiple switch ports to a multicast group, and the switch will forward packets to all the group ports simultaneously, if `mcast_grp` is set. We will use the `Write` RPC method to create a multicast group entry to the switch's forwarding table.

To realize this functionality, we will use the `s1-runtime.json` file provided in this repository. We have already created an entry to hold the required information to create the multicast group. The relevant section of the `s1-runtime.json` file is shown below:

```json
  "multicast_group_entries": [
    {
      "multicast_group_id": 1,
      "replicas": [
        {
          "egress_port": 1,
          "instance": 1
        },
        {
          "egress_port": 2,
          "instance": 1
        },
        {
          "egress_port": 3,
          "instance": 1
        },
        {
          "egress_port": 4,
          "instance": 1
        }
      ]
    }
  ]
}
```

In order to understand the multicast group on the switch we need to study the protobuf definition of the `Write` RCP call and the `PacketReplicationEngineEntry` message, which is used to define multicast groups on the switch. The relevant section of the `p4runtime.proto` file is shown below:

```protobuf

service P4Runtime {
  // Update one or more P4 entities on the target.
  rpc Write(WriteRequest) returns (WriteResponse) {
  }
}

message WriteRequest {
  uint64 device_id = 1;
  uint64 role_id = 2 [deprecated=true];
  string role = 6;
  Uint128 election_id = 3;
  // The write batch, comprising a list of Update operations. The P4Runtime
  // server may arbitrarily reorder messages within a batch to maximize
  // performance.
  repeated Update updates = 4;
  enum Atomicity {
    // Required. This is the default behavior. The batch is processed in a
    // non-atomic manner from a data plane point of view. Each operation within
    // the batch must be attempted even if one or more encounter errors.
    // Every data plane packet is guaranteed to be processed according to
    // table contents as they are between two individual operations of the
    // batch, but there could be several packets processed that see each of
    // these intermediate stages.
    CONTINUE_ON_ERROR = 0;
    // Optional. Operations within the batch are committed to data plane until
    // an error is encountered. At this point, the operations must be rolled
    // back such that both software and data plane state is consistent with the
    // state before the batch was attempted. The resulting behavior is
    // all-or-none, except the batch is not atomic from a data plane point of
    // view. Every data plane packet is guaranteed to be processed according to
    // table contents as they are between two individual operations of the
    // batch, but there could be several packets processed that see each of
    // these intermediate stages.
    ROLLBACK_ON_ERROR = 1;
    // Optional. Every data plane packet is guaranteed to be processed according
    // to table contents before the batch began, or after the batch completed
    // and the operations were programmed to the hardware.
    // The batch is therefore treated as a transaction. 
    DATAPLANE_ATOMIC = 2;
  }
  Atomicity atomicity = 5;
}

message Update {
  enum Type {
    UNSPECIFIED = 0;
    INSERT = 1;
    MODIFY = 2;
    DELETE = 3;
  }
  Type type = 1;
  Entity entity = 2;
}

message Entity {
  oneof entity {
    ExternEntry extern_entry = 1;
    TableEntry table_entry = 2;
    ActionProfileMember action_profile_member = 3;
    ActionProfileGroup action_profile_group = 4;
    MeterEntry meter_entry = 5;
    DirectMeterEntry direct_meter_entry = 6;
    CounterEntry counter_entry = 7;
    DirectCounterEntry direct_counter_entry = 8;
    PacketReplicationEngineEntry packet_replication_engine_entry = 9;
    ValueSetEntry value_set_entry = 10;
    RegisterEntry register_entry = 11;
    DigestEntry digest_entry = 12;
  }
}

// Only one instance of a Packet Replication Engine (PRE) is expected in the
// P4 pipeline. Hence, no instance id is needed to access the PRE.
message PacketReplicationEngineEntry {
  oneof type {
    MulticastGroupEntry multicast_group_entry = 1;
    CloneSessionEntry clone_session_entry = 2;
  }
}

// Used for replicas created for cloning and multicasting actions.
message Replica {
  oneof port_kind {
    // Using uint32 as ports is deprecated, use port field instead.
    uint32 egress_port = 1 [deprecated=true];
    bytes port = 3;
  }
  uint32 instance = 2;
}

// The (port, instance) pair must be unique for each replica in a given
// multicast group entry. A packet may be multicast by setting the
// multicast_group field of PSA ingress output metadata to multicast_group_id
// of a programmed multicast group entry. The port and instance fields of each
// replica's egress input metadata will be set to the respective values
// programmed in the multicast group entry.
message MulticastGroupEntry {
  uint32 multicast_group_id = 1;
  repeated Replica replicas = 2;
}

```

This looks complicated, but don't worry. To create a multicast group on the switch, we need to create a `WriteRequest` message that contains an `Update` message with the `PacketReplicationEngineEntry` entity type. The `PacketReplicationEngineEntry` message should contain multiplr `MulticastGroupEntry` message, one for each switch port, that defines the multicast group ID and the list of replicas (egress ports) that are part of the group.

The Protobuf compiler generates Python classes for all the Protobuf messages defined in the `p4runtime.proto` file. You can use these classes to create the required messages to create a multicast group on the switch and the code can be found under `util/lib/p4/v1/p4runtime_pb2.py`. We also provide for you a small helper funcion, which abstract further the creation of the protobuf messages. You can find this function in the file `util/p4runtime_lib/helper.py`. We also have a similar file for the P4rutime API, in file `util/p4runtime_lib/switch.py`. Below is the helper function that you can use to create the multicast group entry:

```python
# get mc_group_entry
def buildMCEntry(self, mc_group_id, replicas=None):
    mc_entry = p4runtime_pb2.PacketReplicationEngineEntry()
    mc_entry.multicast_group_entry.multicast_group_id = mc_group_id
    if replicas:
        mc_entry.multicast_group_entry.replicas.extend(
            [
                self.get_replicas_pb(replica["egress_port"], replica["instance"])
                for replica in replicas
            ]
        )
    return mc_entry
```

To create the multicast group on the switch, you can use the `buildMCEntry` helper function. The code creates a `PacketReplicationEngineEntry` message object, to which for each replica defined in the `s1-runtime.json` file, it adds a `Replica` message to the `MulticastGroupEntry` message. `Replicas` is a Python List, to which you can `append()` multiple replicas (or `extend()` with the content of the other lists), each defined as a dictionary with the `egress_port` and `instance` fields.

Once the message is created, you can use the `WritePREEntry` RPC method to send the message to the switch. Below is the code of the `WritePREEntry()` method, which you can find in the `util/p4runtime_lib/switch.py` file:

```python
def WritePREEntry(self, pre_entry, dry_run=False):
    request = p4runtime_pb2.WriteRequest()
    request.device_id = self.device_id
    request.election_id.low = 1
    update = request.updates.add()
    update.type = p4runtime_pb2.Update.INSERT
    update.entity.packet_replication_engine_entry.CopyFrom(pre_entry)
    if dry_run:
        print("P4Runtime Write:", request)
    else:
        self.client_stub.Write(request)
```

The `WritePREEntry()` method creates a `WriteRequest` message, sets the device ID and election ID, and adds an `Update` message to the request. The `Update` message is of type `INSERT`, and it contains the `PacketReplicationEngineEntry` message created earlier. Finally, the method sends the `WriteRequest` message to the switch using the `Write` RPC method.

You should also update your `main.p4` file to use the multicast group when forwarding packets as the default action of your ingress control block. The current code use the action `NoAction` as default on the mac table. You should replace that with a new `broadcast()` action that sets the `standard_metadata.mcast_grp` field in the standard_metadata structure to 1, in order to send the packet through the new multicast group. Finally, it is important when you flood a packet to the network, to avoid sending the packet back to the port, to where you received this packet. This can be cststrophic when you connect two learning switches together, as a single packet packet with an unknown destination MAC address can create a broadcast storm that can congest the entire network. To avoid this, you should modify the `MyEgress` control block and drop packets that are destined to the port from which we received a packet. The `MyEgress` control block is executed after the packests ahve been copied and send to the egress ports. If you have a switch with 4 port and you received a packet with an unknown destination MAC address, then the `MyEgress` block will be execute 4 times, once for each egress port and for each packet the `egress_port` field will have the value of the corresponding egress port. The `MyEgress` control block should compare the `egress_port` field in the `standard_metadata` structure with the `ingress_port` field, and if they are equal, drop the packet. Otherwise, you should not perform any operations on the pakcet.

We have created for you a skeleton controller code, which you can find in the file `controller.py`. The code at the moment simple connects to a P4 switch, load the P4 compiled code and terminates. Your task is to extend the `main()` method and add the multicast_group state defined in the `mininet/s1-runtime.json` file in the `s1` P4 switch.  You can use the `buildMCEntry()` helper function to create the `PacketReplicationEngineEntry` message and the `WritePREEntry()` method to send the message to the switch.

To validate that your controller and p4 program work correctly, you should be able to pingall the devices in your network and see that all packets are being flooded to all switch ports (e.g., run wireshark on a host device and check what packet are received on the host network interface).

## Task 2: Implement MAC learning with the P4Runtime API

In the second task, we will implement MAC learning on our P4 switch using the P4Runtime API. MAC learning allows the switch to learn the source MAC addresses of incoming packets and associate them with the corresponding switch ports, enabling efficient forwarding of packets to known destinations. To achieve this functionality, you will need two functionalities: receive packets from the switch and add table entries to the switch.

Packet reception from the switch is essential to implement our MAC learning functionality, i.e. to learn the source incoming port of unknown source  MAC addresses in incoming packets.

To implement this functionality, we will need to modify both our P4 program and the controller code. In the P4 program, we will need to add a new table in the ingress control block to match on the destination MAC address of incoming packets and forward them to the corresponding switch port. If the destination MAC address is not found in the table, the switch will send a `PacketIn` message to the controller using the `StreamChannel` RPC method.

PacketIn messages are used by the switch to send packets to the controller. The switch has a special port called the CPU port, which is used to send packets to the controller. The CPU port number is defined at boot time and 

To receive packets from the switch, we will use the `StreamChannel` RPC method to establish a bidirectional stream between the controller and the switch. The switch will use this stream to send packets to the controller using `PacketIn` messages. The controller will need to listen for these messages and process them accordingly. You can find the relevant section of the `p4runtime.proto` file below:

```protobuf