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
