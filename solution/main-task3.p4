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

/*
 * Header used to carry the input port number for packets sent to the controller
 */
@controller_header("packet_in")
header packet_in_t {
    bit<7> pad;
    bit<9> ingress_port;
}

/*
 * This is a special header for the packet out message.
 * You can set it in your controller using the metadata 
 * element.
 */
@controller_header("packet_out")
header packet_out_t {
    bit<7> pad;
    bit<9> ingress_port;
}

/*
 * Metadata definition, It should match the packet_out and packet_in headers.
 */
struct metadata {
    bit<7> pad;
    bit<9> ingress_port;
}

struct headers {
    packet_in_t packetin;
    packet_out_t packetout;
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
        // Check if the packet is from the CPU port and extract the packet_out header
        transition select (standard_metadata.ingress_port) {
            CPU_PORT: parse_controller_packet_out_header;
            default: parse_ethernet;
        }
    }

    state parse_controller_packet_out_header {
        packet.extract(hdr.packetout);
        packet.extract(hdr.ethernet);
        log_msg("pad {}, ingress {}",{hdr.packetout.pad, hdr.packetout.ingress_port});
        transition accept;
    }
    state parse_ethernet {
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

    //  Used in dmac to forward packet through port.
    action forward(bit<9> egress_port) {
        standard_metadata.egress_spec = egress_port;
    }

    // Used in smac to send packet to controller.
    action forward_to_cpu() {
        meta.ingress_port = standard_metadata.ingress_port;
        standard_metadata.egress_spec = CPU_PORT;
    }

    // Used as default action in dmac table to broadcast packet.
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
        if (standard_metadata.egress_port == CPU_PORT) {
            // send packet to controller. Enable header first and then store the ingress port
            hdr.packetin.setValid();
            hdr.packetin.ingress_port = meta.ingress_port;
        }

        // Ensure broadcast packets are not sent back to the ingress port
        if (standard_metadata.egress_port == standard_metadata.ingress_port) {
            drop();
        }

        // If the packet is coming from the CPU port, check the ingress port in the packet_out header
        if (standard_metadata.ingress_port == CPU_PORT && standard_metadata.egress_port == hdr.packetout.ingress_port) {
            // log_msg("Suppresss message on port {}",{standard_metadata.egress_port});
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
        packet.emit(hdr.packetin);
        packet.emit(hdr.packetout);
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