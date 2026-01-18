/* -*- P4_16 -*- */
#include <core.p4>
#include <v1model.p4>

/*
 * Define the headers the program will recognize
 */
 #define CPU_PORT 255



/*************************************************************************
*********************** H E A D E R S  ***********************************
*************************************************************************/

typedef bit<48> macAddr_t;

header ethernet_t {
    macAddr_t dstAddr;
    macAddr_t srcAddr;
    bit<16>   etherType;
}

@controller_header("packet_in")
header packet_in_t {
    bit<7> pad;
    bit<9> ingress_port;
}

struct metadata {
    bit<7> pad;
    bit<9> ingress_port;
}

struct headers {
    packet_in_t packetin;
    ethernet_t   ethernet;
}

/*************************************************************************
*********************** P A R S E R  ***********************************
*************************************************************************/

parser MyParser(packet_in packet,
                out headers hdr,
                inout metadata meta,
                inout standard_metadata_t standard_metadata) {

    state start {
       packet.extract(hdr.ethernet);
       transition accept;
    }
}

/*************************************************************************
************   C H E C K S U M    V E R I F I C A T I O N   *************
*************************************************************************/

control MyVerifyChecksum(inout headers hdr, inout metadata meta) {
    apply {  }
}


/*************************************************************************
**************  I N G R E S S   P R O C E S S I N G   *******************
*************************************************************************/

control MyIngress(inout headers hdr,
                  inout metadata meta,
                  inout standard_metadata_t standard_metadata) {

    action forward(bit<9> egress_port) {
        standard_metadata.egress_spec = egress_port;
    }

    action forward_to_cpu() {
        meta.ingress_port = standard_metadata.ingress_port;
        standard_metadata.egress_spec = CPU_PORT;
    }

    action broadcast() {
        standard_metadata.mcast_grp = 1; // Broadcast
    }

    table smac {
        key = {
            hdr.ethernet.srcAddr: exact;
        }

        actions = {
            NoAction;
            forward_to_cpu;
        }

        size = 256;
        default_action = forward_to_cpu();
    }

    table dmac {
        key = {
            hdr.ethernet.dstAddr: exact;
        }

        actions = {
            forward;
            broadcast;
        }
        size = 256;
        default_action = broadcast();
    }

    apply {
        if (hdr.ethernet.isValid()) {
             if (smac.apply().hit) {
                 // source MAC known
                dmac.apply();
             } else {

             }
        }
    }
}

/*************************************************************************
****************  E G R E S S   P R O C E S S I N G   *******************
*************************************************************************/

control MyEgress(inout headers hdr,
                 inout metadata meta,
                 inout standard_metadata_t standard_metadata) {
    action drop() {
        mark_to_drop(standard_metadata);
    }

    apply {
        // log_msg("egress port {}, packet out port {}",{standard_metadata.ingress_port, hdr.packetout.ingress_port});
        if (standard_metadata.egress_port == CPU_PORT) {
            // send packet to controller
            hdr.packetin.setValid();
            hdr.packetin.ingress_port = meta.ingress_port;
        }
        if (standard_metadata.egress_port == standard_metadata.ingress_port) {
            drop();
        }
    }
}

/*************************************************************************
*************   C H E C K S U M    C O M P U T A T I O N   **************
*************************************************************************/

control MyComputeChecksum(inout headers  hdr, inout metadata meta) {
    apply { }
}

/*************************************************************************
***********************  D E P A R S E R  *******************************
*************************************************************************/

control MyDeparser(packet_out packet, in headers hdr) {
    apply {
		// parsed headers have to be added again into the packet
        if (hdr.packetin.isValid()) {
            packet.emit(hdr.packetin);
        }
		packet.emit(hdr.ethernet);
	}
}

/*************************************************************************
***********************  S W I T C H  *******************************
*************************************************************************/

V1Switch(
	MyParser(),
	MyVerifyChecksum(),
	MyIngress(),
	MyEgress(),
	MyComputeChecksum(),
	MyDeparser()
) main;