/* -*- P4_16 -*- */

#include <core.p4>

#include <v1model.p4>

const bit<16> TYPE_IPV4 = 0x800;

 

/*************************************************************************

*********************** H E A D E R S  ***********************************

*************************************************************************/

typedef bit<9>  egressSpec_t;

typedef bit<48> macAddr_t;

typedef bit<32> ip4Addr_t;

 

register<bit<10>>(1024) syn_cnt;

register<bit<10>>(1024) syn_ack_cnt;

 

header ethernet_t {

    macAddr_t dstAddr;

    macAddr_t srcAddr;

    bit<16>   etherType;

}

 

header ipv4_t {

    bit<4>    version;

    bit<4>    ihl;

    bit<8>    diffserv;

    bit<16>   totalLen;

    bit<16>   identification;

    bit<3>    flags;

    bit<13>   fragOffset;

    bit<8>    ttl;

    bit<8>    protocol;

    bit<16>   hdrChecksum;

    ip4Addr_t srcAddr;

    ip4Addr_t dstAddr;

}

 

header tcp_t {

    bit<16> srcPort;

    bit<16> dstPort;

    bit<32> seqNo;

    bit<32> ackNo;

    bit<4>  dataOffset;

    bit<4>  res;

    bit<8>  flags;

    bit<16> window;

    bit<16> checksum;

    bit<16> urgentPtr;

}

 

header udp_t {

    bit<16> srcPort;

    bit<16> dstPort;

    bit<16> udplength;

    bit<16> checksum;

}

 

struct metadata {

    bit<10>   flowlet_map_index;

    bit<10>    syn_count;

    bit<10>    syn_ack_count;

}

 

struct headers {

    ethernet_t   ethernet;

    ipv4_t       ipv4;

    tcp_t        tcp;

    udp_t       udp;

}

 

/*************************************************************************

*********************** P A R S E R  ***********************************

*************************************************************************/

parser MyParser(packet_in packet,

                out headers hdr,

                inout metadata meta,

                inout standard_metadata_t standard_metadata) {

 

    state start {

        transition parse_ethernet;

    }

 

    state parse_ethernet {

        packet.extract(hdr.ethernet);

        transition select(hdr.ethernet.etherType) {

            TYPE_IPV4: parse_ipv4;

            default: accept;

        }

    }

 

    state parse_ipv4 {

        packet.extract(hdr.ipv4);

        transition select(hdr.ipv4.protocol) {

            0x06: parse_tcp;

            0x11: parse_udp;

            default: accept;

        }

    }

 

    state parse_tcp {

        packet.extract(hdr.tcp);

        transition accept; 

    }

 

    state parse_udp {

        packet.extract(hdr.udp);

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

 

    action add_syn_cnt() {

        hash(meta.flowlet_map_index, HashAlgorithm.crc16, (bit<16>)0, { hdr.ipv4.srcAddr }, (bit<32>)1024);

        syn_cnt.read(meta.syn_count, (bit<32>)meta.flowlet_map_index);

        meta.syn_count=meta.syn_count+1;

        syn_cnt.write((bit<32>)meta.flowlet_map_index, meta.syn_count);

    }

 

    action add_syn_ack_cnt() {

        hash(meta.flowlet_map_index, HashAlgorithm.crc16, (bit<16>)0, { hdr.ipv4.dstAddr }, (bit<32>)1024);

        syn_ack_cnt.read(meta.syn_ack_count, (bit<32>)meta.flowlet_map_index);

        meta.syn_ack_count=meta.syn_ack_count+1;

        syn_ack_cnt.write((bit<32>)meta.flowlet_map_index, meta.syn_ack_count);

    } 

 

    action drop() {

        mark_to_drop(standard_metadata);

    }

 

    action forward(macAddr_t dstAddr, egressSpec_t port) {

        hdr.ethernet.srcAddr = hdr.ethernet.dstAddr;

        hdr.ethernet.dstAddr = dstAddr;

        standard_metadata.egress_spec = port;

        hdr.ipv4.ttl = hdr.ipv4.ttl - 1;

    }

 

    table ip_forward {

        key = {

            hdr.ipv4.dstAddr: exact;

        }

        actions = {

            forward;

            drop;

        }

        size = 1024;

        default_action = drop();

    }

 

    apply {

        bit<1> set_drop=0;

        if (hdr.tcp.isValid()){

           if(hdr.tcp.flags==2) {

             add_syn_cnt();

    

             hash(meta.flowlet_map_index, HashAlgorithm.crc16, (bit<16>)0, { hdr.ipv4.srcAddr }, (bit<32>)1024);

             bit<10> tmp;

             syn_ack_cnt.read(tmp, (bit<32>)meta.flowlet_map_index);

             if(tmp==0 && meta.syn_count>3){

               set_drop=1;

             }

             if (tmp!=0 && meta.syn_count > (bit<10>)(3+tmp)){

               set_drop=1; 

             }

           } else if (hdr.tcp.flags==0x12) {

             add_syn_ack_cnt();

           }

        }

 

        if( hdr.ipv4.isValid() && set_drop==0){

             ip_forward.apply();

        }

    }

}

 

/*************************************************************************

****************  E G R E S S   P R O C E S S I N G   *******************

*************************************************************************/

control MyEgress(inout headers hdr,

                 inout metadata meta,

                 inout standard_metadata_t standard_metadata) {

    apply {  }

}

 

/*************************************************************************

*************   C H E C K S U M    C O M P U T A T I O N   **************

*************************************************************************/

control MyComputeChecksum(inout headers  hdr, inout metadata meta) {

     apply {

        update_checksum(

            hdr.ipv4.isValid(),

            { hdr.ipv4.version,

              hdr.ipv4.ihl,

              hdr.ipv4.diffserv,

              hdr.ipv4.totalLen,

              hdr.ipv4.identification,

              hdr.ipv4.flags,

              hdr.ipv4.fragOffset,

              hdr.ipv4.ttl,

              hdr.ipv4.protocol,

              hdr.ipv4.srcAddr,

              hdr.ipv4.dstAddr },

            hdr.ipv4.hdrChecksum,

            HashAlgorithm.csum16);

    }

}

 

/*************************************************************************

***********************  D E P A R S E R  *******************************

*************************************************************************/

control MyDeparser(packet_out packet, in headers hdr) {

    apply {

        packet.emit(hdr.ethernet);

        packet.emit(hdr.ipv4);

        packet.emit(hdr.tcp);

        packet.emit(hdr.udp);

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
