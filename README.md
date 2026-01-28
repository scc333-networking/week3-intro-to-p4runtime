# Introduction to the P4Runtime API

In the last lab activity you were introduced to the P4 language and you implement a static P4 Ethernet switch. In this activity you will learn how to implement a P4 controller in Python and implement a basic learning switch. To ease your way into P4 controllers, we will discuss the P4Runtime API, which is used to control P4-programmable switches at runtime. We will use the basic interactions between a P4 controller and a P4-programmable switch to provide an example of how the API works and how to use it. Treat this tutorial as an introduction to GRPC, but not a complete guide. You can find more information about GRPC and Protobuf in the links provided below.

By the end of this activity you will be able to:

- [ ] Understand the P4Runtime API and its components
- [ ] Implement a basic P4 controller using the P4Runtime API
- [ ] Implement a learning switch using P4 and the P4Runtime API

## SDN controllers and Southbound APIs

![Figure 1: SDN architecture with control plane, data plane, and southbound API.](.resources/P4-architecture.png)


In Software-Defined Networking (SDN), the control plane is separated from the data plane. The control plane is responsible for making decisions about how packets should be forwarded, while the data plane is responsible for forwarding packets based on the decisions made by the control plane. In the context of P4, the data plane can be defined using the P4 language. Between the control plane and the data plane we typically need an API that allows the control plane to communicate with the data plane devices. This API is called a southbound API.

In our example of a P4 switch, the P4Runtime API is a southbound API that allows a controller to manage and control P4-programmable devices at runtime. The controller then uses the P4Runtime API to install P4 programs, add and remove table entries, and configure switch parameters. In the first lecture of this course, we discussed the OpenFlow protocol, which is an early example of a southbound API. OpenFlow is a widely used southbound API that allows controllers to manage and control network devices. However, OpenFlow is static and assumes that the data plane is fixed and cannot be changed. Nonetheless, the P4 data plane can vary across programs and devices, and thus we need a more flexible southbound API that can adapt to different P4 programs and devices. The P4Runtime API is designed to be flexible and extensible, allowing it to support different P4 programs and devices. To achieve this flexibility, the P4Runtime API is based on gRPC and Protocol Buffers (Protobuf).

## What is gRPC and Protobuf?

A big challenge in distributed computer systems is the design of communication mechanisms between components. Through the years a number of Remote Procedure Call (RPC) frameworks have been developed to address this challenge. These frameworks allow a program to call procedures (functions) on another machine as if they were local function calls. They offer languages and platform-neutral interfaces to define the procedures and their parameters, and they handle the underlying communication details. As a result, the developer can define the protocol details once and then a compiler generates the necessary code to handle the communication between different components for different languages and platforms. This make the development of distributed systems much easier and less error-prone. Google Protocol Buffers (Protobuf) and gRPC are among the latest frameworks that are widely used in the industry.

The protobuf language is a language-neutral, platform-neutral extensible mechanism for serializing structured data in distributed systems. It is used to define the structure of the data that will be exchanged between different components in a distributed system. The protobuf compiler generates code in different languages (e.g., C++, Java, Python) to serialize and deserialize the data. An example of a protobuf definition is shown below:

```protobuf
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

You can use this code snippet and the protobuf compiler to generate Python classes to serialize and deserialize the `Person` message in different languages. The P4 language uses protobuf to define the structure of P4 tables and other P4 constructs, and the users can use any language to interact with P4-programmable devices. You can find more information about protobuf [here](https://developers.google.com/protocol-buffers), while the P4 protobuf definitions can be found as part of this repository in ``p4runtime/proto/p4/v1/p4runtime.proto``. Protobuf is primarily designed to describe the structure of the messages exchanged between different components. However, it does not provide a mechanism for defining the procedures (functions) that will be called remotely. This is where gRPC comes in.

gRPC builds on protobuf to realize a high-performance, open-source universal RPC framework that can run in any environment. gRPC is the language-independent Interface Definition Language (IDL) that enables client and server applications to communicate transparently, and makes it easier to build connected systems. gRPC uses protobuf to define the structure of the messages exchanged between the client and server, as well as the procedures that can be called remotely. Using this specifications, a developer can build code for any programming language, that allows developers to implement client and servers without the need to write the low-level socket code. An example of a gRPC service definition is shown below:

```protobuf
service PersonService {
  rpc GetPerson (PersonRequest) returns (Person);
  rpc CreatePerson (Person) returns (PersonResponse);
}
```

In this scenario, the `PersonService` defines two RPC methods: `GetPerson` and `CreatePerson`. The `GetPerson` method takes a `PersonRequest` message as input and returns a `Person` message as output, while the `CreatePerson` method takes a `Person` message as input and returns a `PersonResponse` message as output. You can use this code snippet and the protobuf compiler to generate Python classes to implement the client and server for the `PersonService`. You can find more information about gRPC [here](https://grpc.io/docs/).

### P4Runtime API Overview

The P4Runtime API is a gRPC-based API that allows a controller to manage and control P4-programmable devices at runtime. The P4Runtime API is defined using Protobuf, and it provides a set of RPC methods that can be used to interact with P4-programmable devices. The P4Runtime API is defined in the `p4runtime.proto` file, which can be found in the `p4runtime/proto/p4/v1/` directory of this repository.

The P4Runtime API provides a set of RPC methods that can be used to perform various operations on P4-programmable devices. The RPC methods of the P4runtime service are defined in the afformentioned file (`proto/p4/v1/p4runtime.proto`)  and are shown below:

```protobuf
service P4Runtime {
  // Update one or more P4 entities on the target.
  rpc Write(WriteRequest) returns (WriteResponse);

  // Read one or more P4 entities from the target.
  rpc Read(ReadRequest) returns (stream ReadResponse);

  // Sets the P4 forwarding-pipeline config.
  rpc SetForwardingPipelineConfig(SetForwardingPipelineConfigRequest)
      returns (SetForwardingPipelineConfigResponse);

  // Gets the current P4 forwarding-pipeline config.
  rpc GetForwardingPipelineConfig(GetForwardingPipelineConfigRequest)
      returns (GetForwardingPipelineConfigResponse);

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
      returns (stream StreamMessageResponse);

  rpc Capabilities(CapabilitiesRequest) returns (CapabilitiesResponse);
}
```

The `SetForwardingPipelineConfig` RPC method is used to install a P4 program on a P4-programmable device, while the `GetForwardingPipelineConfig` RPC method is used to retrieve the current P4 program installed on a device. You typically use this method upon connecting to a switch to load the P4 program, as generated from the p4c compiler. An example of the data used to load the P4 program can be found in folder `p4src/build/bmv2.json`, but it won't make much sense to understand the details. The P4Runtime service defines the `Write` and `Read` RPC methods which are used to add, modify, delete, and read different properties of the switch. An example of the properties that can be modified using these methods can be found below. Be aware that these methods are **synchronous**, We will only use a small subset of these properties in this activity.

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


The `StreamChannel` RPC method is used to establish a bidirectional stream between the controller and the P4-programmable device, which can be used to send and receive packets and notifications. This is used for asynchronous communication between the controller and the switch. For example, the switch can use this call to forward data from the data plane to the controller using packet-in messages, while the controller can use it to inject packets to the data plane, using  packet-out messages. A list of all the message types used in the P4Runtime API can be found in the `p4runtime.proto` file.

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

To help you in developing your controller code, we provide a small P4Runtime library in the `util/lib/p4_cli/` directory. This library provides helper functions to connect to a P4 switch, load a P4 program, and read and write different properties of the switch. You can use this library to simplify your controller code and focus on the logic of your application. The code is source for the P4 consrtium lab activities and you can find more information about it [here](http://github.com/p4lang/tutorials). We provide pydocs for the library in the `docs/` directory of this repository. You can open the `index.html` file in your web browser to view the documentation.

## Task 1: Configure a switch using the P4Runtime API

In the first lab of this module, we revisited how a learning switch works and identified two key functionalities: **Flooding** and **MAC learning**. Flooding is essential in ensuring that packets reach all possible destinations when the destination MAC address is unknown. MAC learning allows the switch to learn the source MAC addresses of incoming packets and associate them with the corresponding switch ports, enabling efficient forwarding of packets to known destinations.

In this first task, we will extend our P4 static switch and add the ability to flood packets to the switch ports. To achieve this, we will need to use the P4Runtime API to configure a multicast group on the switch. A multicast group is a virtual port, to which we can send a packet using the `standard_metadata.mcast_grp` field in the `MyIngress` block. A controller can add multiple switch ports to a multicast group, and the switch will forward packets to all the group ports simultaneously, if `mcast_grp` is set. We will use the `Write` RPC method to create a multicast group entry to the switch's forwarding table.

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

In order to understand the multicast group on the switch we need to study the protobuf definition of the `Write` RPC call and the `PacketReplicationEngineEntry` message, which is used to define multicast groups on the switch. The relevant section of the `p4runtime.proto` file is shown below:

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

This looks complicated, but don't worry. To create a multicast group on the switch, we need to create a `WriteRequest` message that contains an `Update` message with the `PacketReplicationEngineEntry` entity type. The `PacketReplicationEngineEntry` message should contain multiple `MulticastGroupEntry` messages, one for each switch port, that defines the multicast group ID and the list of replicas (egress ports) that are part of the group.

The Protobuf compiler generates Python classes for all the Protobuf messages defined in the `p4runtime.proto` file. You can use these classes to create the required messages to create a multicast group on the switch and the code can be found under `util/lib/p4/v1/p4runtime_pb2.py`. We also provide a small helper function, which abstracts further the creation of the protobuf messages. You can find this function in the file `util/lib/p4_cli/helper.py`. We also have a similar file for the P4Runtime API in file `util/lib/p4_cli/switch.py`. Below is the helper function that you can use to create the multicast group entry:

```python
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

To create the multicast group on the switch, you can use the `buildMCEntry()` helper function. The code creates a `PacketReplicationEngineEntry` message object, to which for each replica defined in the `s1-runtime.json` file, it adds a `Replica` message to the `MulticastGroupEntry` message. `Replicas` is a Python List, to which you can `append()` multiple replicas (or `extend()` with the content of the other lists), each defined as a dictionary with the `egress_port` and `instance` fields.

Once the message is created, you can use the `WritePREEntry()` RPC method to send the message to the switch. Below is the code of the `WritePREEntry()` method, which you can find in the `util/lib/p4_cli/switch.py` file:

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

The `WritePREEntry()` method creates a `WriteRequest` message, sets the device ID and election ID (Unique IDs of the switch and the controller), and adds an `Update` message to the request. The `Update` message is of type `INSERT`, and it contains the `PacketReplicationEngineEntry` message created earlier. Finally, the method sends the `WriteRequest` message to the switch using the `Write` RPC method.

> Step 1: Extend your P4 program to create a multicast group including all switch ports. 

You should also update your `main.p4` file to use the multicast group when forwarding packets as the default action of your ingress control block. The current code uses the action `NoAction` as default on the mac table. You should replace that with a new `broadcast()` action that sets the `standard_metadata.mcast_grp` field in the standard_metadata structure to 1, in order to send the packet through the new multicast group. Finally, it is important when you flood a packet to the network to avoid sending the packet back to the port from which you received it. This can be catastrophic when you connect two learning switches together, as a single packet with an unknown destination MAC address can create a broadcast storm that can congest the entire network. To avoid this, you should modify the `MyEgress` control block and drop packets that are destined to the port from which we received a packet. The `MyEgress` control block is executed after the packets have been copied and sent to the egress ports. If you have a switch with 4 port and you received a packet with an unknown destination MAC address, then the `MyEgress` block will be executed 4 times, once for each egress port and for each packet the `egress_port` field will have the value of the corresponding egress port. The `MyEgress` control block should compare the `egress_port` field in the `standard_metadata` structure with the `ingress_port` field, and if they are equal, drop the packet. Otherwise, you should not perform any operations on the packet.

We have created for you a skeleton controller code, which you can find in the file `controller.py`. The code currently simply connects to a P4 switch, loads the P4 compiled code and terminates. Your task is to extend the `main()` method and add the multicast_group state defined in the `mininet/s1-runtime.json` file in the `s1` P4 switch.  You can use the `buildMCEntry()` helper function to create the `PacketReplicationEngineEntry` message and the `WritePREEntry()` method to send the message to the switch.

> Step 2: Extend the main.p4 file to include an `action broadcast()` that sets the `standard_metadata.mcast_grp` field to 1 and modify the `MyEgress` control block to drop packets that are being flooded to the ingress port.

In the `MyEgress` control block, use the `standard_metadata.ingress_port` to compare against the `standard_metadata.egress_port`. If they match, drop the packet using the `mark_to_drop()` intrinsic function.

To validate that your controller and p4 program work correctly, you should be able to pingall the devices in your network and see that all packets are being flooded to all switch ports (e.g., run wireshark on a host device and check what packet are received on the host network interface).

## Task 2: Implement MAC learning with the P4Runtime API

In the second task, we will implement MAC learning on our P4 switch using the P4Runtime API and a Python controller. MAC learning allows the switch to learn the source MAC addresses of incoming packets and associate them with the corresponding switch ports, enabling efficient forwarding of packets to known destinations. To achieve this functionality, you will need two functionalities: receive packets from the switch and add table entries to the switch. Figure 2 provides a schematic of that we aim to achieve in this task.

![Figure 2: Example interaction between the controller and the switch for a packet with an unknown destination MAC address. ](.resources/Lecture%2015+16%20-%20BeyondOpenFlow.gif)

The switch implementation from last week, relies on a single table to forward packets. In order to realise the learning functionality, we need an additional table to keep track of known and unknown MAC address. If the source MAC address is present in the table, then the MAC address is known and we can use the forwarding table to process the packet for forwarding. If the MAC is unknown, then the packet must be sent to the controller using the CPU_PORT value as the egress_port.

> Task 2: Add an smac table in the MyIngress stage. The table should implement a default action called `learn`, which will set the egress_port to CPU_PORT. You should also modify the apply code of the block. A packet must first be looked up in the `smac` table. If a match is found (smac.apply().hit is true), then the packet should also be looked up in the dmac table for a forwarding action and sent to the next stage of the pipeline. If the MAC is not found in smac, then no further actions should be applied to the packet, so that the packet is sent to the next stage.

Packet reception from the switch is essential to implement our MAC learning functionality, i.e. to learn the source incoming port of unknown source  MAC addresses in incoming packets. To implement this functionality, we will need to modify both our P4 program and the controller code. In the P4 program, we will need to add a new table in the ingress control block to match on the destination MAC address of incoming packets and forward them to the corresponding switch port. If the destination MAC address is not found in the table, the switch will send a `PacketIn` message to the controller using the `StreamChannel` RPC method. This can be achieved using the special port number 255 or the constant CPU_PORT. To effectively learn the new MAC address, we need to also create a new custom header, which will be sent to the controller, containing the ingress_port of the packet. We explain how this functionality works in the next subsection.

### Understanding Controller Headers: Packet-In and Packet-Out

Before we proceed, it's important to understand how packets are exchanged between the P4 controller and the P4 data plane. The P4Runtime API provides a mechanism for bidirectional packet I/O between the controller and the switch using special controller headers. A **controller header** is a special P4 header that is annotated with the `@controller_header` annotation. These headers carry metadata between the P4 data plane and the controller, enabling communication about packet processing decisions. Their definition is not different from the Ethernet packet and you can define the individual fields using the same syntax. The new header **should** be included in the headers structure. Controller headers are unique in that they are only meaningful at the boundary between the data plane and the control plane—they are not part of the actual packet forwarding on the network.

There are two types of controller headers:

1. **`@controller_header("packet_in")`** – Used for packets going INTO the controller FROM the data plane. When the P4 program sends a packet to the controller (e.g., to the CPU port), any header annotated with this annotation will be included in the `PacketIn` message. This allows the data plane to communicate important metadata to the controller, such as the ingress port where the packet arrived.

2. **`@controller_header("packet_out")`** – Used for packets going OUT from the controller TO the data plane. When the controller sends a packet back to the switch, it uses the `PacketOut` message to specify metadata (via this header) that tells the data plane what to do with the packet, such as the egress port where it should be forwarded.

#### Example: Packet-In and Packet-Out Headers

In the P4 program, these headers might be defined as follows:

```p4
@controller_header("packet_in")
header packet_in_t {
    bit<7> pad;
    bit<9> ingress_port;  // The port where the packet arrived
}

@controller_header("packet_out")
header packet_out_t {
    bit<7> p,,ad;
    bit<9> egress_port;   // The port where the packet should be sent
}

struct metadata {
  bit<7> pad;
  bit<9> egress_port;
}

struct headers {
    ethernet_t ethernet;
    packet_in_t packet_in_hdr;   // Packet-In header
    packet_out_t packet_out_hdr; // Packet-Out header
};
```

In order to include the header in a packet, we need first to user the header structure and call the setValid() function in any control block, e.g. as part of the learn action you can add the following line:

```p4
headers.packet_in_hdr.setValid();
```

and the in the deparser block you need to add the header to the packet:

```p4 
packet.emit(headers.packet_in_hdr);
```

#### How They Work Together

- **Packet-In**: When the P4 program needs to send a packet to the controller (e.g., because the destination MAC is unknown), it prepends the `packet_in_t` header to the packet and sends it to the CPU port. The controller receives this in a `PacketIn` message, which includes the metadata from the `packet_in_t` header, allowing the controller to know which port the packet arrived on.

- **Packet-Out**: After the controller makes a forwarding decision and wants to send the packet back to the data plane, it creates a `PacketOut` message with the packet payload and sets the metadata using the `packet_out_t` header fields to specify the egress port.

### Key Constraints

- At most **one header** can be annotated with `@controller_header("packet_in")`
- At most **one header** can be annotated with `@controller_header("packet_out")`
- These headers are automatically handled by P4Runtime and are not part of the normal packet processing pipeline
- The fields in these headers must be defined in the `metadata` structure to ensure proper mapping between the data plane and control plane 

> Step 3: Define a `@controller_header("packet_in")` annotation in the P4 program to carry the ingress port information for packets sent to the controller. Create a corresponding metadata structure field in your P4 program with the same layout as the packet_in header. Modify the controller code to handle `PacketIn` messages, extract the ingress port from the controller header, and use this information to learn MAC addresses and add entries to the forwarding table. Update the `metadata structure` to contain the same fields as the PacketIn header. Make sure the P4 program sets the `ingress_port` field in the `packet_in` header when sending packets to the controller and that the header is set to valid before sending the packet to the CPU port.

> Step 4: Update the MyDeparse code to emit the packet_in header if it is valid.

The final step now is to process the packet in in your controller code. If you have carefully studied the `p4runtime.proto` file, you will notice that the `PacketIn` message is send using the `StreamChannel` RPC method, as a possible content of a `StreamMessageResponse` message. Furthermore, the `StreamChannel` method definion is slightly different from the `Write` and `Read` methods, since the input parameter and the return value are defined as streams, which means that both the controller and the switch can send multiple messages asynchronously. You can consider this method as a long-lived connection between the controller and the switch, where both sides can send and receive messages at any time. You can imagine this as two [`Queue`](https://docs.python.org/3/library/queue.html), one for sending messages from the controller to the switch and another for sending messages from the switch to the controller. The controller can read messages from the switch by iterating over the incoming stream, and it can send messages to the switch by writing to the outgoing stream.

The `util/lib/switch.py` file provides a `PacketIn()` method that allows you to read `PacketIn` messages from the P4Runtime channel. Calling the `PacketIn()` method will block and wait until a new `PacketIn` message is received from the switch. You can build a loop in your controller code to continuously read `PacketIn` messages from the switch and process them accordingly.

The `PacketIn` message contains the packet data, as well as,  a `metadata` field, which contains the metadata associated with the packet. The metadata is defined using the `PacketMetadata` message, which contains the metadata ID and the metadata value. The metadata ID is defined in the P4 program using the `@controller_header("packet_in")` annotation. The P4Info file generated by the p4c compiler contains the mapping between the metadata ID and the header fields defined in the P4 program. You can use this mapping to extract the ingress port from the `PacketIn` message received from the switch.

Any field defined in the `packet_in` header should also be defined in the `metadata` structure in the P4 program. This is essential for the P4Runtime API to map the header fields to the metadata fields in the `PacketIn` message. You can access the `metadata` structure in the different control blocks as an `inout` parameter. You can use this structure to set the values of the metadata fields before sending the packet to the controller. For example, in the `learn` action, you can set the `ingress_port` field in the `metadata` structure to the value of the `standard_metadata.ingress_port` field.

You will need now to modify the controller code to handle `PacketIn` messages received from the switch. When a `PacketIn` message is received, the controller should extract the ingress port from the `PacketIn` header and use this information to learn the source MAC address of the packet. The controller should then add an entry to the `smac` table in the switch, associating the source MAC address with the ingress port. You can use the `WriteTableEntry` method provided in the `util/lib/p4_cli/switch.py` file to add entries to the switch's forwarding table. In order to process the `PacketIn` messages, you can use the [Python scapy library](https://scapy.readthedocs.io/en/latest/usage.html#binary-string) to parse the packet data and extract the Ethernet header information, including the source MAC address. Each field from the PacketIn header will be available in the metadata field of the PacketIn message. You will need to iterate over the metadata field and find the metadata ID that corresponds to the ingress port. Once you have extracted the ingress port, you can use it to learn the source MAC address of the packet and add an entry to the `smac` and `dmac` table in the switch.

```python
# read a packaet
packetin = s1.PacketIn()

# Extract Ethernet header and any subsequent headers using Scapy
a = Ether(bytes(packetin.packet.payload))
print("Packet source MAC: %s" % a.src)

# Accessing ingress port from PacketIn metadata, assuming metadata ID 1 corresponds to ingress_port
port = int.from_bytes(packetin.packet.metadata[1].value, byteorder='big')
```

> Step 5: Modify the controller code to handle `PacketIn` messages, extract the ingress port from the controller header, and use this information to learn MAC addresses and add entries to the forwarding table.

At the end of this task, you should be able to pingall the devices in your network and see that packets are being forwarded correctly based on the learned MAC addresses. You can use Wireshark on a host device to check what packets are received on the host network interface and verify that the learning switch is functioning as expected. If you use ping to test the connectivity between hosts, you should see that the first ping packet is lost (since the MAC address is unknown), but subsequent ping packets should be delivered successfully. The next task will allow you to fix this issue.

## Task 3: Injecting packets to the data plane

If we test our current learning switch implementation, you will notice that the first packet sent to a host with an unknown destination MAC address will not be delivered, since the packet is sent to the controller, which learns the source MAC address and adds the corresponding table entry, but the original packet is dropped. To solve this issue, we can adopt two options for our switch. One approach can be to clone the packet in the data plane and send a copy to the controller for MAC learning, while forwarding the original packet to the multicast group for flooding. This is the most efficient approach and we will leave the solution as an optional exercise for you to implement. The solution requires from the controller to create a clone session on the switch using the `PacketReplicationEngineEntry` message type, similar to what we did in Task 1 for the multicast group. The clone session will define two replicas: one for the CPU port and one for the multicast group. The P4 program will need to be modified to use the clone action instead of sending the packet to the controller directly.

The second approach, which we will implement in this task, is to have the controller re-inject the packet back into the data plane after learning the source MAC address. This approach is less efficient, as it requires additional communication between the controller and the switch, but it will allow us to understand better the P4Runtime API and how to use it to inject packets into the data plane.

The base idea is that we will inject the packet back into the P4 pipeline and let the default pipeline manage the packet. In this case, because the `smac` table will contain an entry, the `MyIngress` control block will ignore the packet and the forwarding will occur using the `dmac`. If we learnt the MAC address of the receiver, then the packet will be forwarded to the correct port. Otherwise, it will be flooded to all ports using the multicast group. Essential for correct flooding is to include the original ingress port in our packet so that the packet being re-injected can be dropped if it reaches the ingress port (to prevent broadcast storms). 

To achieve this, we need to define a `@controller_header("packet_out")` annotation in the P4 program, similar to the `@controller_header("packet_in")` annotation we defined earlier. This header will carry the ingress port information for the packet being re-injected into the data plane. Once the header is defined, we can move into creating the `PacketOut` message in the controller.

> Step 1: Define the `@controller_header("packet_out")` annotation in the P4 program

To achieve this functionality, we will use the `PacketOut` message type to send packets from the controller to the switch. The `PacketOut` message contains the packet data and the egress port to which the packet should be sent. The controller will need to create a `PacketOut` message for each packet that needs to be re-injected into the data plane and send it to the switch using the `StreamChannel` RPC method. You can find the relevant section of the `p4runtime.proto` file below:

```protobuf
message StreamMessageRequest {
  oneof update {
    MasterArbitrationUpdate arbitration = 1;
    PacketOut packet = 2;
    DigestListAck digest_ack = 3;
    .google.protobuf.Any other = 4;
  }
}

message PacketOut {
  bytes payload = 1;
  // This will be based on P4 header annotated as
  // @controller_header("packet_out").
  // At most one P4 header can have this annotation.
  repeated PacketMetadata metadata = 2;
}

// Any metadata associated with Packet-IO (controller Packet-In or Packet-Out)
// needs to be modeled as P4 headers carrying special annotations
// @controller_header("packet_out") and @controller_header("packet_in")
// respectively. There can be at most one header each with these annotations.
// These special headers are captured in P4Info ControllerPacketMetadata.
message PacketMetadata {
  // This refers to Metadata.id coming from P4Info ControllerPacketMetadata.
  uint32 metadata_id = 1;
  bytes value = 2;
}
```

The P4 helper class provides a helper function to create the `PacketOut` message, which you can find in the `util/lib/p4_cli/helper.py` file. Below is the code of the `buildPacketOut()` helper function:

```python
def buildPacketOut(self, payload, metadata=None):
    """Build a PacketOut message for injecting packets to the data plane."""
    packet_out = p4runtime_pb2.PacketOut()
    packet_out.payload = payload
    if metadata:
        packet_out.metadata.extend(
            [
                self.get_metadata_pb(metadata_id, value)
                for metadata_id, value in metadata.items()
            ]
        )
    return packet_out
```

The metadata parameter is a Python dictionary, where the keys are the metadata IDs and the values are the metadata values. The code creates a `PacketOut` message object, sets the payload field, and for each metadata entry in the dictionary, it adds a `PacketMetadata` message to the `metadata` field.

> Step 2: In your Python controller, create a `PacketOut` message for each packet that needs to be re-injected into the data plane. You can use the `buildPacketOut()` helper function to create the `PacketOut` message. The code should extract the packet data from the `PacketIn` message received from the switch and set it as the payload of the `PacketOut` message. The code should also set the ingress port of the original packet as metadata in the `PacketOut` message, using the metadata ID defined in the P4 program.

Our code edits in the controller and we need now to move to the P4 program. You code changes must update the `MyParser` block to extract the packet out header. You can modify the start transition and based on whether the packet comes from the CPU_PORT or not, you can extract the `packet_out_t` header. Secondly, you need to modify the `MyEgress` control block to use the ingress port information from the `packet_out_t` metadata to drop a packet if the packet is being broadcast and the egress port matches the original ingress port (passed via the packet_out header metadata). 

> Step 3: Update the `MyParser` block to extract the `packet_out_t` header when the packet comes from the CPU_PORT and the `MyEgress` control block to drop packets that are being flooded.

Your implementation should now be complete and you should be able to ping between any two hosts with 0% packet loss. You can use Wireshark on the host interfaces to verify that packets are being forwarded correctly. **You can identify yourselves as a P4 developer.**

## Useful Links

* [P4 Language Specification](https://p4.org/p4-spec/docs/P4-16-v1.3.0-spec.html)
* [P4Runtime API Specification](https://p4.org/p4-spec/docs/P4Runtime-Spec.html)
* [gRPC Documentation](https://grpc.io/docs/)
* [Protocol Buffers Documentation](https://developers.google.com/protocol-buffers)
* [P4 Tutorial](http://github.com/p4lang/tutorials)