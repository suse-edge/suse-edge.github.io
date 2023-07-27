#!/bin/bash

usage() {
    echo "$0 [options]"
    echo "Options:"
    echo "-m, --mode         this is test mode, xran or timer mode , -m xran , -m timer"
    echo "-a, --    this is l1app ,oru or testmac application, example: -a l1app , -a oru , -a testmac"
    echo "-h, --help              show help info and exit"
    exit 0
}
test_mode=""
test_app=""
while getopts 'a::m:' OPT; do
    case ${OPT} in
      m)
          test_mode="$OPTARG";;
      a)
          test_app="$OPTARG";;
      ?)
          usage
      esac
done

if [ $OPTIND -eq 1 ]; then
    usage
fi
PCIDEVICE_INTEL_COM_INTEL_FEC_5G=$(env|grep PCIDEVICE_INTEL_COM_INTEL_FEC_5G= |awk -F '=' '{print $2}')
export INTEL_COM_INTEL_CPULIST=$(cat /sys/fs/cgroup/cpuset/cpuset.cpus)

if [ $test_mode = "xran" ]; then
  PCIaddr1=""
  PCIaddr2=""
  PCIaddr3=""
  PCIaddr4=""
  if [ -n "$PCIDEVICE_INTEL_COM_INTEL_FEC_5G" ]; then
    PCIaddr1=$(echo $PCIDEVICE_INTEL_COM_INTEL_SRIOV_ODU | sed "s/,/\n/g" | sort | sed -n "1p")
    PCIaddr2=$(echo $PCIDEVICE_INTEL_COM_INTEL_SRIOV_ODU | sed "s/,/\n/g" | sort | sed -n "2p")
    PCIaddr3=$(echo $PCIDEVICE_INTEL_COM_INTEL_SRIOV_ODU | sed "s/,/\n/g" | sort | sed -n "3p")
    PCIaddr4=$(echo $PCIDEVICE_INTEL_COM_INTEL_SRIOV_ODU | sed "s/,/\n/g" | sort | sed -n "4p")

    cd /home/flexran/bin/nr5g/gnb/l1/orancfg/sub3_mu0_10mhz_4x4/gnb/
    #sed -i "s/0000:18:00.0/$PCIDEVICE_INTEL_COM_INTEL_FEC_5G/g" phycfg_xran.xml
    sed -i "s/dpdkBasebandDevice>0000:[0-9,a-z][0-9,a-z]:[0-9,a-z][0-9,a-z].[0-9]<\/dpdkBasebandDevice/dpdkBasebandDevice>$PCIDEVICE_INTEL_COM_INTEL_FEC_5G<\/dpdkBasebandDevice/g" phycfg_xran.xml
    sed -i "s/<dpdkIovaMode>0<\/dpdkIovaMode>/<dpdkIovaMode>1<\/dpdkIovaMode>/g" phycfg_xran.xml
    #sed -i "s/0000:1a:02.0/$PCIaddr1/g;s/0000:1a:02.1/$PCIaddr2/g" xrancfg_sub6_oru.xml
    sed -i "s/PciBusAddoRu0Vf0>0000:[0-9,a-z][0-9,a-z]:[0-9,a-z][0-9,a-z].[0-9]<\/PciBusAddoRu0Vf0/PciBusAddoRu0Vf0>$PCIaddr1<\/PciBusAddoRu0Vf0/g" xrancfg_sub6_oru.xml
    sed -i "s/PciBusAddoRu0Vf1>0000:[0-9,a-z][0-9,a-z]:[0-9,a-z][0-9,a-z].[0-9]<\/PciBusAddoRu0Vf1/PciBusAddoRu0Vf1>$PCIaddr2<\/PciBusAddoRu0Vf1/g" xrancfg_sub6_oru.xml
    sed -i "s/PciBusAddoRu1Vf0>0000:[0-9,a-z][0-9,a-z]:[0-9,a-z][0-9,a-z].[0-9]<\/PciBusAddoRu1Vf0/PciBusAddoRu1Vf0>$PCIaddr3<\/PciBusAddoRu1Vf0/g" xrancfg_sub6_oru.xml
    sed -i "s/PciBusAddoRu1Vf1>0000:[0-9,a-z][0-9,a-z]:[0-9,a-z][0-9,a-z].[0-9]<\/PciBusAddoRu1Vf1/PciBusAddoRu1Vf1>$PCIaddr4<\/PciBusAddoRu1Vf1/g" xrancfg_sub6_oru.xml
    sed -i "s/oRuRem0Mac0>[0-9,a-z][0-9,a-z]:[0-9,a-z][0-9,a-z]:[0-9,a-z][0-9,a-z]:[0-9,a-z][0-9,a-z]:[0-9,a-z][0-9,a-z]:[0-9,a-z][0-9,a-z]<\/oRuRem0Mac0/oRuRem0Mac0>00:11:22:33:00:01<\/oRuRem0Mac0/g" xrancfg_sub6_oru.xml
    sed -i "s/oRuRem0Mac1>[0-9,a-z][0-9,a-z]:[0-9,a-z][0-9,a-z]:[0-9,a-z][0-9,a-z]:[0-9,a-z][0-9,a-z]:[0-9,a-z][0-9,a-z]:[0-9,a-z][0-9,a-z]<\/oRuRem0Mac1/oRuRem0Mac1>00:11:22:33:00:11<\/oRuRem0Mac1/g" xrancfg_sub6_oru.xml
    sed -i "s/oRuRem1Mac0>[0-9,a-z][0-9,a-z]:[0-9,a-z][0-9,a-z]:[0-9,a-z][0-9,a-z]:[0-9,a-z][0-9,a-z]:[0-9,a-z][0-9,a-z]:[0-9,a-z][0-9,a-z]<\/oRuRem1Mac0/oRuRem1Mac0>00:11:22:33:00:21<\/oRuRem1Mac0/g" xrancfg_sub6_oru.xml
    sed -i "s/oRuRem1Mac1>[0-9,a-z][0-9,a-z]:[0-9,a-z][0-9,a-z]:[0-9,a-z][0-9,a-z]:[0-9,a-z][0-9,a-z]:[0-9,a-z][0-9,a-z]:[0-9,a-z][0-9,a-z]<\/oRuRem1Mac1/oRuRem1Mac1>00:11:22:33:00:31<\/oRuRem1Mac1/g" xrancfg_sub6_oru.xml
    sed -i "s/oRuEthLinkSpeed>25/oRuEthLinkSpeed>100/g" xrancfg_sub6_oru.xml
    cd /home/flexran/bin/nr5g/gnb/l1/orancfg/sub3_mu0_20mhz_4x4/gnb/
    #sed -i "s/0000:18:00.0/$PCIDEVICE_INTEL_COM_INTEL_FEC_5G/g" phycfg_xran.xml
    sed -i "s/dpdkBasebandDevice>0000:[0-9,a-z][0-9,a-z]:[0-9,a-z][0-9,a-z].[0-9]<\/dpdkBasebandDevice/dpdkBasebandDevice>$PCIDEVICE_INTEL_COM_INTEL_FEC_5G<\/dpdkBasebandDevice/g" phycfg_xran.xml
    sed -i "s/<dpdkIovaMode>0<\/dpdkIovaMode>/<dpdkIovaMode>1<\/dpdkIovaMode>/g" phycfg_xran.xml
    #sed -i "s/0000:1a:02.0/$PCIaddr1/g;s/0000:1a:02.1/$PCIaddr2/g" xrancfg_sub6_oru.xml
    sed -i "s/PciBusAddoRu0Vf0>0000:[0-9,a-z][0-9,a-z]:[0-9,a-z][0-9,a-z].[0-9]<\/PciBusAddoRu0Vf0/PciBusAddoRu0Vf0>$PCIaddr1<\/PciBusAddoRu0Vf0/g" xrancfg_sub6_oru.xml
    sed -i "s/PciBusAddoRu0Vf1>0000:[0-9,a-z][0-9,a-z]:[0-9,a-z][0-9,a-z].[0-9]<\/PciBusAddoRu0Vf1/PciBusAddoRu0Vf1>$PCIaddr2<\/PciBusAddoRu0Vf1/g" xrancfg_sub6_oru.xml
    sed -i "s/PciBusAddoRu1Vf0>0000:[0-9,a-z][0-9,a-z]:[0-9,a-z][0-9,a-z].[0-9]<\/PciBusAddoRu1Vf0/PciBusAddoRu1Vf0>$PCIaddr3<\/PciBusAddoRu1Vf0/g" xrancfg_sub6_oru.xml
    sed -i "s/PciBusAddoRu1Vf1>0000:[0-9,a-z][0-9,a-z]:[0-9,a-z][0-9,a-z].[0-9]<\/PciBusAddoRu1Vf1/PciBusAddoRu1Vf1>$PCIaddr4<\/PciBusAddoRu1Vf1/g" xrancfg_sub6_oru.xml
    sed -i "s/oRuRem0Mac0>[0-9,a-z][0-9,a-z]:[0-9,a-z][0-9,a-z]:[0-9,a-z][0-9,a-z]:[0-9,a-z][0-9,a-z]:[0-9,a-z][0-9,a-z]:[0-9,a-z][0-9,a-z]<\/oRuRem0Mac0/oRuRem0Mac0>00:11:22:33:00:01<\/oRuRem0Mac0/g" xrancfg_sub6_oru.xml
    sed -i "s/oRuRem0Mac1>[0-9,a-z][0-9,a-z]:[0-9,a-z][0-9,a-z]:[0-9,a-z][0-9,a-z]:[0-9,a-z][0-9,a-z]:[0-9,a-z][0-9,a-z]:[0-9,a-z][0-9,a-z]<\/oRuRem0Mac1/oRuRem0Mac1>00:11:22:33:00:11<\/oRuRem0Mac1/g" xrancfg_sub6_oru.xml
    sed -i "s/oRuRem1Mac0>[0-9,a-z][0-9,a-z]:[0-9,a-z][0-9,a-z]:[0-9,a-z][0-9,a-z]:[0-9,a-z][0-9,a-z]:[0-9,a-z][0-9,a-z]:[0-9,a-z][0-9,a-z]<\/oRuRem1Mac0/oRuRem1Mac0>00:11:22:33:00:21<\/oRuRem1Mac0/g" xrancfg_sub6_oru.xml
    sed -i "s/oRuRem1Mac1>[0-9,a-z][0-9,a-z]:[0-9,a-z][0-9,a-z]:[0-9,a-z][0-9,a-z]:[0-9,a-z][0-9,a-z]:[0-9,a-z][0-9,a-z]:[0-9,a-z][0-9,a-z]<\/oRuRem1Mac1/oRuRem1Mac1>00:11:22:33:00:31<\/oRuRem1Mac1/g" xrancfg_sub6_oru.xml
    sed -i "s/oRuEthLinkSpeed>25/oRuEthLinkSpeed>100/g" xrancfg_sub6_oru.xml
    #cd /home/flexran/bin/nr5g/gnb/l1/orancfg/sub3_mu0_20mhz_sub3_mu1_20mhz_4x4/gnb/
    ##sed -i "s/0000:19:00.0/$PCIDEVICE_INTEL_COM_INTEL_FEC_5G/g" phycfg_xran.xml
    #sed -i "s/dpdkBasebandDevice>0000:[0-9,a-z][0-9,a-z]:[0-9,a-z][0-9,a-z].[0-9]<\/dpdkBasebandDevice/dpdkBasebandDevice>$PCIDEVICE_INTEL_COM_INTEL_FEC_5G<\/dpdkBasebandDevice/g" phycfg_xran.xml
    #sed -i "s/<dpdkIovaMode>0<\/dpdkIovaMode>/<dpdkIovaMode>1<\/dpdkIovaMode>/g" phycfg_xran.xml
    ##sed -i "s/0000:1a:02.0/$PCIaddr1/g;s/0000:1a:02.1/$PCIaddr2/g" xrancfg_sub6_oru.xml
    ##sed -i "s/0000:1a:02.2/$PCIaddr3/g;s/0000:1a:02.3/$PCIaddr4/g" xrancfg_sub6_oru.xml
    #sed -i "s/PciBusAddoRu0Vf0>0000:[0-9,a-z][0-9,a-z]:[0-9,a-z][0-9,a-z].[0-9]<\/PciBusAddoRu0Vf0/PciBusAddoRu0Vf0>$PCIaddr1<\/PciBusAddoRu0Vf0/g" xrancfg_sub6_oru.xml
    #sed -i "s/PciBusAddoRu0Vf1>0000:[0-9,a-z][0-9,a-z]:[0-9,a-z][0-9,a-z].[0-9]<\/PciBusAddoRu0Vf1/PciBusAddoRu0Vf1>$PCIaddr2<\/PciBusAddoRu0Vf1/g" xrancfg_sub6_oru.xml
    #sed -i "s/PciBusAddoRu1Vf0>0000:[0-9,a-z][0-9,a-z]:[0-9,a-z][0-9,a-z].[0-9]<\/PciBusAddoRu1Vf0/PciBusAddoRu1Vf0>$PCIaddr3<\/PciBusAddoRu1Vf0/g" xrancfg_sub6_oru.xml
    #sed -i "s/PciBusAddoRu1Vf1>0000:[0-9,a-z][0-9,a-z]:[0-9,a-z][0-9,a-z].[0-9]<\/PciBusAddoRu1Vf1/PciBusAddoRu1Vf1>$PCIaddr4<\/PciBusAddoRu1Vf1/g" xrancfg_sub6_oru.xml
    #sed -i "s/oRuRem0Mac0>[0-9,a-z][0-9,a-z]:[0-9,a-z][0-9,a-z]:[0-9,a-z][0-9,a-z]:[0-9,a-z][0-9,a-z]:[0-9,a-z][0-9,a-z]:[0-9,a-z][0-9,a-z]<\/oRuRem0Mac0/oRuRem0Mac0>00:11:22:33:00:01<\/oRuRem0Mac0/g" xrancfg_sub6_oru.xml
    #sed -i "s/oRuRem0Mac1>[0-9,a-z][0-9,a-z]:[0-9,a-z][0-9,a-z]:[0-9,a-z][0-9,a-z]:[0-9,a-z][0-9,a-z]:[0-9,a-z][0-9,a-z]:[0-9,a-z][0-9,a-z]<\/oRuRem0Mac1/oRuRem0Mac1>00:11:22:33:00:11<\/oRuRem0Mac1/g" xrancfg_sub6_oru.xml
    #sed -i "s/oRuRem1Mac0>[0-9,a-z][0-9,a-z]:[0-9,a-z][0-9,a-z]:[0-9,a-z][0-9,a-z]:[0-9,a-z][0-9,a-z]:[0-9,a-z][0-9,a-z]:[0-9,a-z][0-9,a-z]<\/oRuRem1Mac0/oRuRem1Mac0>00:11:22:33:00:21<\/oRuRem1Mac0/g" xrancfg_sub6_oru.xml
    #sed -i "s/oRuRem1Mac1>[0-9,a-z][0-9,a-z]:[0-9,a-z][0-9,a-z]:[0-9,a-z][0-9,a-z]:[0-9,a-z][0-9,a-z]:[0-9,a-z][0-9,a-z]:[0-9,a-z][0-9,a-z]<\/oRuRem1Mac1/oRuRem1Mac1>00:11:22:33:00:31<\/oRuRem1Mac1/g" xrancfg_sub6_oru.xml
    #cd /home/flexran/bin/nr5g/gnb/l1/orancfg/sub3_mu0_20mhz_sub6_mu1_100mhz_4x4/gnb/
    ##sed -i "s/0000:19:00.0/$PCIDEVICE_INTEL_COM_INTEL_FEC_5G/g" phycfg_xran.xml
    #sed -i "s/dpdkBasebandDevice>0000:[0-9,a-z][0-9,a-z]:[0-9,a-z][0-9,a-z].[0-9]<\/dpdkBasebandDevice/dpdkBasebandDevice>$PCIDEVICE_INTEL_COM_INTEL_FEC_5G<\/dpdkBasebandDevice/g" phycfg_xran.xml
    #sed -i "s/<dpdkIovaMode>0<\/dpdkIovaMode>/<dpdkIovaMode>1<\/dpdkIovaMode>/g" phycfg_xran.xml
    ##sed -i "s/0000:1a:02.0/$PCIaddr1/g;s/0000:1a:02.1/$PCIaddr2/g" xrancfg_sub6_oru.xml
    ##sed -i "s/0000:1a:02.2/$PCIaddr3/g;s/0000:1a:02.3/$PCIaddr4/g" xrancfg_sub6_oru.xml
    #sed -i "s/PciBusAddoRu0Vf0>0000:[0-9,a-z][0-9,a-z]:[0-9,a-z][0-9,a-z].[0-9]<\/PciBusAddoRu0Vf0/PciBusAddoRu0Vf0>$PCIaddr1<\/PciBusAddoRu0Vf0/g" xrancfg_sub6_oru.xml
    #sed -i "s/PciBusAddoRu0Vf1>0000:[0-9,a-z][0-9,a-z]:[0-9,a-z][0-9,a-z].[0-9]<\/PciBusAddoRu0Vf1/PciBusAddoRu0Vf1>$PCIaddr2<\/PciBusAddoRu0Vf1/g" xrancfg_sub6_oru.xml
    #sed -i "s/PciBusAddoRu1Vf0>0000:[0-9,a-z][0-9,a-z]:[0-9,a-z][0-9,a-z].[0-9]<\/PciBusAddoRu1Vf0/PciBusAddoRu1Vf0>$PCIaddr3<\/PciBusAddoRu1Vf0/g" xrancfg_sub6_oru.xml
    #sed -i "s/PciBusAddoRu1Vf1>0000:[0-9,a-z][0-9,a-z]:[0-9,a-z][0-9,a-z].[0-9]<\/PciBusAddoRu1Vf1/PciBusAddoRu1Vf1>$PCIaddr4<\/PciBusAddoRu1Vf1/g" xrancfg_sub6_oru.xml
    #sed -i "s/oRuRem0Mac0>[0-9,a-z][0-9,a-z]:[0-9,a-z][0-9,a-z]:[0-9,a-z][0-9,a-z]:[0-9,a-z][0-9,a-z]:[0-9,a-z][0-9,a-z]:[0-9,a-z][0-9,a-z]<\/oRuRem0Mac0/oRuRem0Mac0>00:11:22:33:00:01<\/oRuRem0Mac0/g" xrancfg_sub6_oru.xml
    #sed -i "s/oRuRem0Mac1>[0-9,a-z][0-9,a-z]:[0-9,a-z][0-9,a-z]:[0-9,a-z][0-9,a-z]:[0-9,a-z][0-9,a-z]:[0-9,a-z][0-9,a-z]:[0-9,a-z][0-9,a-z]<\/oRuRem0Mac1/oRuRem0Mac1>00:11:22:33:00:11<\/oRuRem0Mac1/g" xrancfg_sub6_oru.xml
    #sed -i "s/oRuRem1Mac0>[0-9,a-z][0-9,a-z]:[0-9,a-z][0-9,a-z]:[0-9,a-z][0-9,a-z]:[0-9,a-z][0-9,a-z]:[0-9,a-z][0-9,a-z]:[0-9,a-z][0-9,a-z]<\/oRuRem1Mac0/oRuRem1Mac0>00:11:22:33:00:21<\/oRuRem1Mac0/g" xrancfg_sub6_oru.xml
    #sed -i "s/oRuRem1Mac1>[0-9,a-z][0-9,a-z]:[0-9,a-z][0-9,a-z]:[0-9,a-z][0-9,a-z]:[0-9,a-z][0-9,a-z]:[0-9,a-z][0-9,a-z]:[0-9,a-z][0-9,a-z]<\/oRuRem1Mac1/oRuRem1Mac1>00:11:22:33:00:31<\/oRuRem1Mac1/g" xrancfg_sub6_oru.xml
    cd /home/flexran/bin/nr5g/gnb/l1/orancfg/sub6_mu1_100mhz_4x4/gnb/
    #sed -i "s/0000:17:00.0/$PCIDEVICE_INTEL_COM_INTEL_FEC_5G/g" phycfg_xran.xml
    sed -i "s/dpdkBasebandDevice>0000:[0-9,a-z][0-9,a-z]:[0-9,a-z][0-9,a-z].[0-9]<\/dpdkBasebandDevice/dpdkBasebandDevice>$PCIDEVICE_INTEL_COM_INTEL_FEC_5G<\/dpdkBasebandDevice/g" phycfg_xran.xml
    sed -i "s/<dpdkIovaMode>0<\/dpdkIovaMode>/<dpdkIovaMode>1<\/dpdkIovaMode>/g" phycfg_xran.xml
    #sed -i "s/0000:1a:02.0/$PCIaddr1/g;s/0000:1a:02.1/$PCIaddr2/g" xrancfg_sub6_oru.xml
    sed -i "s/PciBusAddoRu0Vf0>0000:[0-9,a-z][0-9,a-z]:[0-9,a-z][0-9,a-z].[0-9]<\/PciBusAddoRu0Vf0/PciBusAddoRu0Vf0>$PCIaddr1<\/PciBusAddoRu0Vf0/g" xrancfg_sub6_oru.xml
    sed -i "s/PciBusAddoRu0Vf1>0000:[0-9,a-z][0-9,a-z]:[0-9,a-z][0-9,a-z].[0-9]<\/PciBusAddoRu0Vf1/PciBusAddoRu0Vf1>$PCIaddr2<\/PciBusAddoRu0Vf1/g" xrancfg_sub6_oru.xml
    sed -i "s/PciBusAddoRu1Vf0>0000:[0-9,a-z][0-9,a-z]:[0-9,a-z][0-9,a-z].[0-9]<\/PciBusAddoRu1Vf0/PciBusAddoRu1Vf0>$PCIaddr3<\/PciBusAddoRu1Vf0/g" xrancfg_sub6_oru.xml
    sed -i "s/PciBusAddoRu1Vf1>0000:[0-9,a-z][0-9,a-z]:[0-9,a-z][0-9,a-z].[0-9]<\/PciBusAddoRu1Vf1/PciBusAddoRu1Vf1>$PCIaddr4<\/PciBusAddoRu1Vf1/g" xrancfg_sub6_oru.xml
    sed -i "s/oRuRem0Mac0>[0-9,a-z][0-9,a-z]:[0-9,a-z][0-9,a-z]:[0-9,a-z][0-9,a-z]:[0-9,a-z][0-9,a-z]:[0-9,a-z][0-9,a-z]:[0-9,a-z][0-9,a-z]<\/oRuRem0Mac0/oRuRem0Mac0>00:11:22:33:00:01<\/oRuRem0Mac0/g" xrancfg_sub6_oru.xml
    sed -i "s/oRuRem0Mac1>[0-9,a-z][0-9,a-z]:[0-9,a-z][0-9,a-z]:[0-9,a-z][0-9,a-z]:[0-9,a-z][0-9,a-z]:[0-9,a-z][0-9,a-z]:[0-9,a-z][0-9,a-z]<\/oRuRem0Mac1/oRuRem0Mac1>00:11:22:33:00:11<\/oRuRem0Mac1/g" xrancfg_sub6_oru.xml
    sed -i "s/oRuRem1Mac0>[0-9,a-z][0-9,a-z]:[0-9,a-z][0-9,a-z]:[0-9,a-z][0-9,a-z]:[0-9,a-z][0-9,a-z]:[0-9,a-z][0-9,a-z]:[0-9,a-z][0-9,a-z]<\/oRuRem1Mac0/oRuRem1Mac0>00:11:22:33:00:21<\/oRuRem1Mac0/g" xrancfg_sub6_oru.xml
    sed -i "s/oRuRem1Mac1>[0-9,a-z][0-9,a-z]:[0-9,a-z][0-9,a-z]:[0-9,a-z][0-9,a-z]:[0-9,a-z][0-9,a-z]:[0-9,a-z][0-9,a-z]:[0-9,a-z][0-9,a-z]<\/oRuRem1Mac1/oRuRem1Mac1>00:11:22:33:00:31<\/oRuRem1Mac1/g" xrancfg_sub6_oru.xml
    sed -i "s/oRuEthLinkSpeed>25/oRuEthLinkSpeed>100/g" xrancfg_sub6_oru.xml
    #cd /home/flexran/bin/nr5g/gnb/l1/orancfg/mmwave_mu3_100mhz_2x2/gnb/
    ##sed -i "s/0000:8b:00.0/$PCIDEVICE_INTEL_COM_INTEL_FEC_5G/g" phycfg_xran.xml
    #sed -i "s/dpdkBasebandDevice>0000:[0-9,a-z][0-9,a-z]:[0-9,a-z][0-9,a-z].[0-9]<\/dpdkBasebandDevice/dpdkBasebandDevice>$PCIDEVICE_INTEL_COM_INTEL_FEC_5G<\/dpdkBasebandDevice/g" phycfg_xran.xml
    #sed -i "s/<dpdkIovaMode>0<\/dpdkIovaMode>/<dpdkIovaMode>1<\/dpdkIovaMode>/g" phycfg_xran.xml
    ##sed -i "s/0000:51:01.0/$PCIaddr1/g;s/0000:51:09.0/$PCIaddr2/g" xrancfg_sub6_oru.xml
    #sed -i "s/PciBusAddoRu0Vf0>0000:[0-9,a-z][0-9,a-z]:[0-9,a-z][0-9,a-z].[0-9]<\/PciBusAddoRu0Vf0/PciBusAddoRu0Vf0>$PCIaddr1<\/PciBusAddoRu0Vf0/g" xrancfg_sub6_oru.xml
    #sed -i "s/PciBusAddoRu0Vf1>0000:[0-9,a-z][0-9,a-z]:[0-9,a-z][0-9,a-z].[0-9]<\/PciBusAddoRu0Vf1/PciBusAddoRu0Vf1>$PCIaddr2<\/PciBusAddoRu0Vf1/g" xrancfg_sub6_oru.xml
    #sed -i "s/PciBusAddoRu1Vf0>0000:[0-9,a-z][0-9,a-z]:[0-9,a-z][0-9,a-z].[0-9]<\/PciBusAddoRu1Vf0/PciBusAddoRu1Vf0>$PCIaddr3<\/PciBusAddoRu1Vf0/g" xrancfg_sub6_oru.xml
    #sed -i "s/PciBusAddoRu1Vf1>0000:[0-9,a-z][0-9,a-z]:[0-9,a-z][0-9,a-z].[0-9]<\/PciBusAddoRu1Vf1/PciBusAddoRu1Vf1>$PCIaddr4<\/PciBusAddoRu1Vf1/g" xrancfg_sub6_oru.xml
    #sed -i "s/oRuRem0Mac0>[0-9,a-z][0-9,a-z]:[0-9,a-z][0-9,a-z]:[0-9,a-z][0-9,a-z]:[0-9,a-z][0-9,a-z]:[0-9,a-z][0-9,a-z]:[0-9,a-z][0-9,a-z]<\/oRuRem0Mac0/oRuRem0Mac0>00:11:22:33:00:01<\/oRuRem0Mac0/g" xrancfg_sub6_oru.xml
    #sed -i "s/oRuRem0Mac1>[0-9,a-z][0-9,a-z]:[0-9,a-z][0-9,a-z]:[0-9,a-z][0-9,a-z]:[0-9,a-z][0-9,a-z]:[0-9,a-z][0-9,a-z]:[0-9,a-z][0-9,a-z]<\/oRuRem0Mac1/oRuRem0Mac1>00:11:22:33:00:11<\/oRuRem0Mac1/g" xrancfg_sub6_oru.xml
    #sed -i "s/oRuRem1Mac0>[0-9,a-z][0-9,a-z]:[0-9,a-z][0-9,a-z]:[0-9,a-z][0-9,a-z]:[0-9,a-z][0-9,a-z]:[0-9,a-z][0-9,a-z]:[0-9,a-z][0-9,a-z]<\/oRuRem1Mac0/oRuRem1Mac0>00:11:22:33:00:21<\/oRuRem1Mac0/g" xrancfg_sub6_oru.xml
    #sed -i "s/oRuRem1Mac1>[0-9,a-z][0-9,a-z]:[0-9,a-z][0-9,a-z]:[0-9,a-z][0-9,a-z]:[0-9,a-z][0-9,a-z]:[0-9,a-z][0-9,a-z]:[0-9,a-z][0-9,a-z]<\/oRuRem1Mac1/oRuRem1Mac1>00:11:22:33:00:31<\/oRuRem1Mac1/g" xrancfg_sub6_oru.xml
    cd /home/flexran/bin/nr5g/gnb/testmac/
    cp ../l1/orancfg/sub3_mu0_10mhz_4x4/gnb/testmac_clxsp_mu0_10mhz_hton_oru.cfg ./
    cp ../l1/orancfg/sub3_mu0_20mhz_4x4/gnb/testmac_clxsp_mu0_20mhz_hton_oru.cfg ./
    #cp ../l1/orancfg/sub3_mu0_20mhz_sub3_mu1_20mhz_4x4/gnb/testmac_clxsp_multi_numerology_oru.cfg ./
    #cp ../l1/orancfg/sub3_mu0_20mhz_sub6_mu1_100mhz_4x4/gnb/testmac_clxsp_multi_numerology_oru.cfg ./testmac_clxsp_multi_numerology_oru_sub6.cfg
    cp ../l1/orancfg/sub6_mu1_100mhz_4x4/gnb/testmac_clxsp_mu1_100mhz_hton_oru.cfg ./
    #cp ../l1/orancfg/mmwave_mu3_100mhz_2x2/gnb/testmac_icxsp_mu3_100mhz_hton_oru.cfg ./
    sed -i "s/<dpdkIovaMode>0<\/dpdkIovaMode>/<dpdkIovaMode>1<\/dpdkIovaMode>/g" ./testmac_cfg.xml
    sed -i "s/<PhyCoreCheck>1<\/PhyCoreCheck>/<PhyCoreCheck>0<\/PhyCoreCheck>/g" ./testmac_cfg.xml
    #open core pining
    cpulist=$(cat /sys/fs/cgroup/cpuset/cpuset.cpus)
    startd=$(echo $cpulist|sed "s/,/\n/g" | sort | sed -n "1p")
    twod=$(echo $cpulist|sed "s/,/\n/g" | sort | sed -n "2p")
    if [ -z $startd ] ; then
      echo "cpuset is empty"
      exit 0
    fi
    startd_f=$(echo $startd|awk -F '-' '{print $1}')
    startd_e=$(echo $startd|awk -F '-' '{print $2}')
    #echo "startd_f:$startd_f,start_e:$startd_e"
    start_n=$(expr $startd_e - $startd_f)
    if [ $start_n -gt 20 ] ; then
      exit 0
    fi

    twod_f=$(echo $twod|sed "s/-/\n/g" | sort | sed -n "1p")
    twod_e=$(echo $twod|sed "s/-/\n/g" | sort | sed -n "2p")
    #start_n=`expr $startd_e - $startd_f`
    twod_n=`expr $twod_e - $twod_f`

    systemthread=$twod_f
    timerThread=$(expr $twod_f + 1)
    FpgaDriverCpuInfo=$(expr $twod_f + 2)
    FrontHaulCpuInfo=$(expr $twod_f + 2)
    radioDpdkMaster=$(expr $twod_f + 1)
    xRANThread=$(expr $twod_f + 3)
    wlsRxThread=$(expr $twod_f + 4)
    runThread=$(expr $twod_f + 5)
    cd /home/flexran/bin/nr5g/gnb/l1/orancfg/sub3_mu0_10mhz_4x4/gnb/
    sed -i "s/<systemThread>0, 0, 0<\/systemThread>/<systemThread>$systemthread, 0, 0<\/systemThread>/g" phycfg_xran.xml
    sed -i "s/<timerThread>2, 96, 0<\/timerThread>/<timerThread>$timerThread, 96, 0<\/timerThread>/g" phycfg_xran.xml
    sed -i "s/<FpgaDriverCpuInfo>3, 96, 0<\/FpgaDriverCpuInfo>/<FpgaDriverCpuInfo>$FpgaDriverCpuInfo, 96, 0<\/FpgaDriverCpuInfo>/g" phycfg_xran.xml
    sed -i "s/<FrontHaulCpuInfo>3, 96, 0<\/FrontHaulCpuInfo>/<FrontHaulCpuInfo>$FrontHaulCpuInfo, 96, 0<\/FrontHaulCpuInfo>/g" phycfg_xran.xml
    sed -i "s/<radioDpdkMaster>2, 99, 0<\/radioDpdkMaster>/<radioDpdkMaster>$radioDpdkMaster, 99, 0<\/radioDpdkMaster>/g" phycfg_xran.xml

    sed -i "s/<xRANThread>18, 96, 0<\/xRANThread>/<xRANThread>$xRANThread, 96, 0<\/xRANThread>/g" xrancfg_sub6_oru.xml

    cd /home/flexran/bin/nr5g/gnb/l1/orancfg/sub3_mu0_20mhz_4x4/gnb/
    sed -i "s/<systemThread>2, 0, 0<\/systemThread>/<systemThread>$systemthread, 0, 0<\/systemThread>/g" phycfg_xran.xml
    sed -i "s/<timerThread>0, 96, 0<\/timerThread>/<timerThread>$timerThread, 96, 0<\/timerThread>/g" phycfg_xran.xml
    sed -i "s/<FpgaDriverCpuInfo>3, 96, 0<\/FpgaDriverCpuInfo>/<FpgaDriverCpuInfo>$FpgaDriverCpuInfo, 96, 0<\/FpgaDriverCpuInfo>/g" phycfg_xran.xml
    sed -i "s/<FrontHaulCpuInfo>3, 96, 0<\/FrontHaulCpuInfo>/<FrontHaulCpuInfo>$FrontHaulCpuInfo, 96, 0<\/FrontHaulCpuInfo>/g" phycfg_xran.xml
    sed -i "s/<radioDpdkMaster>2, 99, 0<\/radioDpdkMaster>/<radioDpdkMaster>$radioDpdkMaster, 99, 0<\/radioDpdkMaster>/g" phycfg_xran.xml

    sed -i "s/<xRANThread>18, 96, 0<\/xRANThread>/<xRANThread>$xRANThread, 96, 0<\/xRANThread>/g" xrancfg_sub6_oru.xml

    #cd /home/flexran/bin/nr5g/gnb/l1/orancfg/sub3_mu0_20mhz_sub3_mu1_20mhz_4x4/gnb/
    #sed -i "s/<systemThread>2, 0, 0<\/systemThread>/<systemThread>$systemthread, 0, 0<\/systemThread>/g" phycfg_xran.xml
    #sed -i "s/<timerThread>0, 96, 0<\/timerThread>/<timerThread>$timerThread, 96, 0<\/timerThread>/g" phycfg_xran.xml
    #sed -i "s/<FpgaDriverCpuInfo>3, 96, 0<\/FpgaDriverCpuInfo>/<FpgaDriverCpuInfo>$FpgaDriverCpuInfo, 96, 0<\/FpgaDriverCpuInfo>/g" phycfg_xran.xml
    #sed -i "s/<FrontHaulCpuInfo>3, 96, 0<\/FrontHaulCpuInfo>/<FrontHaulCpuInfo>$FrontHaulCpuInfo, 96, 0<\/FrontHaulCpuInfo>/g" phycfg_xran.xml
    #sed -i "s/<radioDpdkMaster>2, 99, 0<\/radioDpdkMaster>/<radioDpdkMaster>$radioDpdkMaster, 99, 0<\/radioDpdkMaster>/g" phycfg_xran.xml
#
    #sed -i "s/<xRANThread>18, 96, 0<\/xRANThread>/<xRANThread>$xRANThread, 96, 0<\/xRANThread>/g" xrancfg_sub6_oru.xml
#
    #cd /home/flexran/bin/nr5g/gnb/l1/orancfg/sub3_mu0_20mhz_sub6_mu1_100mhz_4x4/gnb/
    #sed -i "s/<systemThread>2, 0, 0<\/systemThread>/<systemThread>$systemthread, 0, 0<\/systemThread>/g" phycfg_xran.xml
    #sed -i "s/<timerThread>0, 96, 0<\/timerThread>/<timerThread>$timerThread, 96, 0<\/timerThread>/g" phycfg_xran.xml
    #sed -i "s/<FpgaDriverCpuInfo>3, 96, 0<\/FpgaDriverCpuInfo>/<FpgaDriverCpuInfo>$FpgaDriverCpuInfo, 96, 0<\/FpgaDriverCpuInfo>/g" phycfg_xran.xml
    #sed -i "s/<FrontHaulCpuInfo>3, 96, 0<\/FrontHaulCpuInfo>/<FrontHaulCpuInfo>$FrontHaulCpuInfo, 96, 0<\/FrontHaulCpuInfo>/g" phycfg_xran.xml
    #sed -i "s/<radioDpdkMaster>2, 99, 0<\/radioDpdkMaster>/<radioDpdkMaster>$radioDpdkMaster, 99, 0<\/radioDpdkMaster>/g" phycfg_xran.xml
#
    #sed -i "s/<xRANThread>18, 96, 0<\/xRANThread>/<xRANThread>$xRANThread, 96, 0<\/xRANThread>/g" xrancfg_sub6_oru.xml
#
    cd /home/flexran/bin/nr5g/gnb/l1/orancfg/sub6_mu1_100mhz_4x4/gnb/
    sed -i "s/<systemThread>2, 0, 0<\/systemThread>/<systemThread>$systemthread, 0, 0<\/systemThread>/g" phycfg_xran.xml
    sed -i "s/<timerThread>0, 96, 0<\/timerThread>/<timerThread>$timerThread, 96, 0<\/timerThread>/g" phycfg_xran.xml
    sed -i "s/<FpgaDriverCpuInfo>3, 96, 0<\/FpgaDriverCpuInfo>/<FpgaDriverCpuInfo>$FpgaDriverCpuInfo, 96, 0<\/FpgaDriverCpuInfo>/g" phycfg_xran.xml
    sed -i "s/<FrontHaulCpuInfo>3, 96, 0<\/FrontHaulCpuInfo>/<FrontHaulCpuInfo>$FrontHaulCpuInfo, 96, 0<\/FrontHaulCpuInfo>/g" phycfg_xran.xml
    sed -i "s/<radioDpdkMaster>2, 99, 0<\/radioDpdkMaster>/<radioDpdkMaster>$radioDpdkMaster, 99, 0<\/radioDpdkMaster>/g" phycfg_xran.xml

    sed -i "s/<xRANThread>18, 96, 0<\/xRANThread>/<xRANThread>$xRANThread, 96, 0<\/xRANThread>/g" xrancfg_sub6_oru.xml

    #cd /home/flexran/bin/nr5g/gnb/l1/orancfg/mmwave_mu3_100mhz_2x2/gnb/
    #sed -i "s/<systemThread>0, 0, 0<\/systemThread>/<systemThread>$systemthread, 0, 0<\/systemThread>/g" phycfg_xran.xml
    #sed -i "s/<timerThread>2, 96, 0<\/timerThread>/<timerThread>$timerThread, 96, 0<\/timerThread>/g" phycfg_xran.xml
    #sed -i "s/<FpgaDriverCpuInfo>3, 96, 0<\/FpgaDriverCpuInfo>/<FpgaDriverCpuInfo>$FpgaDriverCpuInfo, 96, 0<\/FpgaDriverCpuInfo>/g" phycfg_xran.xml
    #sed -i "s/<FrontHaulCpuInfo>3, 96, 0<\/FrontHaulCpuInfo>/<FrontHaulCpuInfo>$FrontHaulCpuInfo, 96, 0<\/FrontHaulCpuInfo>/g" phycfg_xran.xml
    #sed -i "s/<radioDpdkMaster>2, 99, 0<\/radioDpdkMaster>/<radioDpdkMaster>$radioDpdkMaster, 99, 0<\/radioDpdkMaster>/g" phycfg_xran.xml
#
    #sed -i "s/<xRANThread>18, 96, 0<\/xRANThread>/<xRANThread>$xRANThread, 96, 0<\/xRANThread>/g" xrancfg_sub6_oru.xml

    cd /home/flexran/bin/nr5g/gnb/testmac
    sed -i "s/<systemThread>0, 0, 0<\/systemThread>/<systemThread>$systemthread, 0, 0<\/systemThread>/g" testmac_cfg.xml
    sed -i "s/<wlsRxThread>1, 90, 0<\/wlsRxThread>/<wlsRxThread>$wlsRxThread, 90, 0<\/wlsRxThread>/g" testmac_cfg.xml
    sed -i "s/<runThread>0, 89, 0<\/runThread>/<runThread>$runThread, 89, 0<\/runThread>/g" testmac_cfg.xml

    dec2hex(){
      printf "%x" $1
    }
    #a=$(dec2hex 55)
    #a=`echo "ibase=10;obase=16;8"`
    startd_f1=$(expr $startd_f + 1)
    startd_f2=$(expr $startd_f + 2)
    startd_f3=$(expr $startd_f + 3)
    startd_f4=$(expr $startd_f + 4)
    startd_f5=$(expr $startd_f + 5)
    startd_f6=$(expr $startd_f + 6)
    startd_f7=$(expr $startd_f + 7)
    startd_f8=$(expr $startd_f + 8)
    startd_f9=$(expr $startd_f + 9)
    startd_f10=$(expr $startd_f + 10)
    startd_f11=$(expr $startd_f + 11)
    startd_f12=$(expr $startd_f + 12)
    startd_f13=$(expr $startd_f + 13)
    startd_f14=$(expr $startd_f + 14)
    startd_f15=$(expr $startd_f + 15)
    if [ $start_n -lt 15 ] ; then
      echo "configure cpu failed, Please modify the parameters manually"
      exit 0
    fi

    a6=$((1<<$startd_f | 1 << $startd_f1 | 1 << $startd_f2 | 1 << $startd_f3 | 1<<$startd_f4 | 1<<$startd_f5))
    b6=$(dec2hex $a6)
    a2=$((1<<$startd_f | 1 << $startd_f1))
    b2=$(dec2hex $a2)

    a3=$((1<<$startd_f | 1 << $startd_f1 | 1 << $startd_f2))
    b3=$(dec2hex $a3)
    a5=$((1<<$startd_f | 1 << $startd_f1 | 1 << $startd_f2 | 1 << $startd_f3 | 1<<$startd_f4 ))
    b5=$(dec2hex $a5)
    a4=$((1<<$startd_f | 1 << $startd_f1 | 1 << $startd_f2 | 1 << $startd_f3))
    b4=$(dec2hex $a4)
    a12=$((1<<$startd_f | 1 << $startd_f1 | 1 << $startd_f2 | 1 << $startd_f3 | 1<<$startd_f4 | 1<<$startd_f5 | 1 << $startd_f6 | 1<<$startd_f7 | 1<<$startd_f8 |1 << $startd_f9 | 1<<$startd_f10 | 1<<$startd_f11 ))
    b12=$(dec2hex $a12)

    a8=$((1<<$startd_f | 1 << $startd_f1 | 1 << $startd_f2 | 1 << $startd_f3 | 1<<$startd_f4 | 1<<$startd_f5 | 1 << $startd_f6 | 1<<$startd_f7))
    b8=$(dec2hex $a8)
    a16=$((1<<$startd_f | 1 << $startd_f1 | 1 << $startd_f2 | 1 << $startd_f3 | 1<<$startd_f4 | 1<<$startd_f5 | 1 << $startd_f6 | 1<<$startd_f7 | 1<<$startd_f8 |1 << $startd_f9 | 1<<$startd_f10 | 1<<$startd_f11 | 1<<$startd_f12 | 1<<$startd_f13 | 1<<$startd_f14 | 1<<$startd_f15))
    b16=$(dec2hex $a16)
    a14=$((1<<$startd_f | 1 << $startd_f1 | 1 << $startd_f2 | 1 << $startd_f3 | 1<<$startd_f4 | 1<<$startd_f5 | 1 << $startd_f6 | 1<<$startd_f7 | 1<<$startd_f8 |1 << $startd_f9 | 1<<$startd_f10 | 1<<$startd_f11 | 1<<$startd_f12 | 1<<$startd_f13 ))
    b14=$(dec2hex $a14)
    a10=$((1<<$startd_f | 1 << $startd_f1 | 1 << $startd_f2 | 1 << $startd_f3 | 1<<$startd_f4 | 1<<$startd_f5 | 1 << $startd_f6 | 1<<$startd_f7 | 1<<$startd_f8 |1 << $startd_f9 | 1<<$startd_f10 ))
    b10=$(dec2hex $a10)
    a9=$((1<<$startd_f | 1 << $startd_f1 | 1 << $startd_f2 | 1 << $startd_f3 | 1<<$startd_f4 | 1<<$startd_f5 | 1 << $startd_f6 | 1<<$startd_f7 | 1<<$startd_f8 ))
    b9=$(dec2hex $a9)

    #echo "0x$b"
    sed -i "s/3f0003f0/$b12/g" /home/flexran/bin/nr5g/gnb/testmac/testmac_clxsp_mu0_10mhz_hton_oru.cfg
    sed -i "s/ff000ff0/$b16/g" /home/flexran/bin/nr5g/gnb/testmac/testmac_clxsp_mu0_20mhz_hton_oru.cfg
    sed -i "s/7F0007F0/$b14/g" /home/flexran/bin/nr5g/gnb/testmac/testmac_clxsp_mu1_100mhz_hton_oru.cfg
    sed -i "s/1f0001f0/$b10/g" /home/flexran/bin/nr5g/gnb/testmac/testmac_clxsp_multi_numerology_oru.cfg
    sed -i "s/ff000ff0/$b16/g" /home/flexran/bin/nr5g/gnb/testmac/testmac_clxsp_multi_numerology_oru_sub6.cfg
    sed -i "s/7000000070/$b9/g" /home/flexran/bin/nr5g/gnb/testmac/testmac_icxsp_mu3_100mhz_hton_oru.cfg
  fi
  if [ -z "$PCIDEVICE_INTEL_COM_INTEL_FEC_5G" ]; then
    PCIaddr1=$(echo $PCIDEVICE_INTEL_COM_INTEL_SRIOV_ORU | sed "s/,/\n/g" | sort | sed -n "1p")
    PCIaddr2=$(echo $PCIDEVICE_INTEL_COM_INTEL_SRIOV_ORU | sed "s/,/\n/g" | sort | sed -n "2p")
    PCIaddr3=$(echo $PCIDEVICE_INTEL_COM_INTEL_SRIOV_ORU | sed "s/,/\n/g" | sort | sed -n "3p")
    PCIaddr4=$(echo $PCIDEVICE_INTEL_COM_INTEL_SRIOV_ORU | sed "s/,/\n/g" | sort | sed -n "4p")



    cd /home/flexran/bin/nr5g/gnb/l1/orancfg/sub3_mu0_10mhz_4x4/oru/
    #sed -i "s/0000:21:02.0/$PCIaddr1/g;s/0000:21:02.1/$PCIaddr2/g" run_o_ru.sh
    sed -i "s/vf_addr_o_xu_a \"0000:[0-9,a-z][0-9,a-z]:[0-9,a-z][0-9,a-z].[0-9],0000:[0-9,a-z][0-9,a-z]:[0-9,a-z][0-9,a-z].[0-9]\"/vf_addr_o_xu_a \"$PCIaddr1,$PCIaddr2\"/g" run_o_ru.sh
    sed -i "s/vf_addr_o_xu_b \"0000:[0-9,a-z][0-9,a-z]:[0-9,a-z][0-9,a-z].[0-9],0000:[0-9,a-z][0-9,a-z]:[0-9,a-z][0-9,a-z].[0-9]\"/vf_addr_o_xu_b \"$PCIaddr3,$PCIaddr4\"/g" run_o_ru.sh
    sed -i "s/oXuRem0Mac0=[0-9,a-z][0-9,a-z]:[0-9,a-z][0-9,a-z]:[0-9,a-z][0-9,a-z]:[0-9,a-z][0-9,a-z]:[0-9,a-z][0-9,a-z]:[0-9,a-z][0-9,a-z]/oXuRem0Mac0=00:11:22:33:00:00/g" usecase_ru.cfg
    sed -i "s/oXuRem0Mac1=[0-9,a-z][0-9,a-z]:[0-9,a-z][0-9,a-z]:[0-9,a-z][0-9,a-z]:[0-9,a-z][0-9,a-z]:[0-9,a-z][0-9,a-z]:[0-9,a-z][0-9,a-z]/oXuRem0Mac1=00:11:22:33:00:10/g" usecase_ru.cfg
    sed -i "s/oXuRem1Mac0=[0-9,a-z][0-9,a-z]:[0-9,a-z][0-9,a-z]:[0-9,a-z][0-9,a-z]:[0-9,a-z][0-9,a-z]:[0-9,a-z][0-9,a-z]:[0-9,a-z][0-9,a-z]/oXuRem1Mac0=00:11:22:33:00:20/g" usecase_ru.cfg
    sed -i "s/oXuRem1Mac1=[0-9,a-z][0-9,a-z]:[0-9,a-z][0-9,a-z]:[0-9,a-z][0-9,a-z]:[0-9,a-z][0-9,a-z]:[0-9,a-z][0-9,a-z]:[0-9,a-z][0-9,a-z]/oXuRem1Mac1=00:11:22:33:00:30/g" usecase_ru.cfg
    echo "iovaMode=1" >> usecase_ru.cfg

    cd /home/flexran/bin/nr5g/gnb/l1/orancfg/sub3_mu0_20mhz_4x4/oru/
    #sed -i "s/0000:21:02.0/$PCIaddr1/g;s/0000:21:02.1/$PCIaddr2/g" run_o_ru.sh
    sed -i "s/vf_addr_o_xu_a \"0000:[0-9,a-z][0-9,a-z]:[0-9,a-z][0-9,a-z].[0-9],0000:[0-9,a-z][0-9,a-z]:[0-9,a-z][0-9,a-z].[0-9]\"/vf_addr_o_xu_a \"$PCIaddr1,$PCIaddr2\"/g" run_o_ru.sh
    sed -i "s/vf_addr_o_xu_b \"0000:[0-9,a-z][0-9,a-z]:[0-9,a-z][0-9,a-z].[0-9],0000:[0-9,a-z][0-9,a-z]:[0-9,a-z][0-9,a-z].[0-9]\"/vf_addr_o_xu_b \"$PCIaddr3,$PCIaddr4\"/g" run_o_ru.sh
    sed -i "s/oXuRem0Mac0=[0-9,a-z][0-9,a-z]:[0-9,a-z][0-9,a-z]:[0-9,a-z][0-9,a-z]:[0-9,a-z][0-9,a-z]:[0-9,a-z][0-9,a-z]:[0-9,a-z][0-9,a-z]/oXuRem0Mac0=00:11:22:33:00:00/g" usecase_ru.cfg
    sed -i "s/oXuRem0Mac1=[0-9,a-z][0-9,a-z]:[0-9,a-z][0-9,a-z]:[0-9,a-z][0-9,a-z]:[0-9,a-z][0-9,a-z]:[0-9,a-z][0-9,a-z]:[0-9,a-z][0-9,a-z]/oXuRem0Mac1=00:11:22:33:00:10/g" usecase_ru.cfg
    sed -i "s/oXuRem1Mac0=[0-9,a-z][0-9,a-z]:[0-9,a-z][0-9,a-z]:[0-9,a-z][0-9,a-z]:[0-9,a-z][0-9,a-z]:[0-9,a-z][0-9,a-z]:[0-9,a-z][0-9,a-z]/oXuRem1Mac0=00:11:22:33:00:20/g" usecase_ru.cfg
    sed -i "s/oXuRem1Mac1=[0-9,a-z][0-9,a-z]:[0-9,a-z][0-9,a-z]:[0-9,a-z][0-9,a-z]:[0-9,a-z][0-9,a-z]:[0-9,a-z][0-9,a-z]:[0-9,a-z][0-9,a-z]/oXuRem1Mac1=00:11:22:33:00:30/g" usecase_ru.cfg

    echo "iovaMode=1" >> usecase_ru.cfg

    #cd /home/flexran/bin/nr5g/gnb/l1/orancfg/sub3_mu0_20mhz_sub3_mu1_20mhz_4x4/oru/
    ##sed -i "s/0000:21:02.0/$PCIaddr1/g;s/0000:21:02.1/$PCIaddr2/g" run_o_ru.sh
    ##sed -i "s/0000:21:02.2/$PCIaddr3/g;s/0000:21:02.3/$PCIaddr4/g" run_o_ru.sh
    #sed -i "s/vf_addr_o_xu_a \"0000:[0-9,a-z][0-9,a-z]:[0-9,a-z][0-9,a-z].[0-9],0000:[0-9,a-z][0-9,a-z]:[0-9,a-z][0-9,a-z].[0-9]\"/vf_addr_o_xu_a \"$PCIaddr1,$PCIaddr2\"/g" run_o_ru.sh
    #sed -i "s/vf_addr_o_xu_b \"0000:[0-9,a-z][0-9,a-z]:[0-9,a-z][0-9,a-z].[0-9],0000:[0-9,a-z][0-9,a-z]:[0-9,a-z][0-9,a-z].[0-9]\"/vf_addr_o_xu_b \"$PCIaddr3,$PCIaddr4\"/g" run_o_ru.sh
    #sed -i "s/oXuRem0Mac0=[0-9,a-z][0-9,a-z]:[0-9,a-z][0-9,a-z]:[0-9,a-z][0-9,a-z]:[0-9,a-z][0-9,a-z]:[0-9,a-z][0-9,a-z]:[0-9,a-z][0-9,a-z]/oXuRem0Mac0=00:11:22:33:00:00/g" usecase_ru.cfg
    #sed -i "s/oXuRem0Mac1=[0-9,a-z][0-9,a-z]:[0-9,a-z][0-9,a-z]:[0-9,a-z][0-9,a-z]:[0-9,a-z][0-9,a-z]:[0-9,a-z][0-9,a-z]:[0-9,a-z][0-9,a-z]/oXuRem0Mac1=00:11:22:33:00:10/g" usecase_ru.cfg
    #sed -i "s/oXuRem1Mac0=[0-9,a-z][0-9,a-z]:[0-9,a-z][0-9,a-z]:[0-9,a-z][0-9,a-z]:[0-9,a-z][0-9,a-z]:[0-9,a-z][0-9,a-z]:[0-9,a-z][0-9,a-z]/oXuRem1Mac0=00:11:22:33:00:20/g" usecase_ru.cfg
    #sed -i "s/oXuRem1Mac1=[0-9,a-z][0-9,a-z]:[0-9,a-z][0-9,a-z]:[0-9,a-z][0-9,a-z]:[0-9,a-z][0-9,a-z]:[0-9,a-z][0-9,a-z]:[0-9,a-z][0-9,a-z]/oXuRem1Mac1=00:11:22:33:00:30/g" usecase_ru.cfg
    #echo "iovaMode=1" >> usecase_ru.cfg
#
    #cd /home/flexran/bin/nr5g/gnb/l1/orancfg/sub3_mu0_20mhz_sub6_mu1_100mhz_4x4/oru/
    ##sed -i "s/0000:21:02.0/$PCIaddr1/g;s/0000:21:02.1/$PCIaddr2/g" run_o_ru.sh
    ##sed -i "s/0000:21:02.2/$PCIaddr3/g;s/0000:21:02.3/$PCIaddr4/g" run_o_ru.sh
    #sed -i "s/vf_addr_o_xu_a \"0000:[0-9,a-z][0-9,a-z]:[0-9,a-z][0-9,a-z].[0-9],0000:[0-9,a-z][0-9,a-z]:[0-9,a-z][0-9,a-z].[0-9]\"/vf_addr_o_xu_a \"$PCIaddr1,$PCIaddr2\"/g" run_o_ru.sh
    #sed -i "s/vf_addr_o_xu_b \"0000:[0-9,a-z][0-9,a-z]:[0-9,a-z][0-9,a-z].[0-9],0000:[0-9,a-z][0-9,a-z]:[0-9,a-z][0-9,a-z].[0-9]\"/vf_addr_o_xu_b \"$PCIaddr3,$PCIaddr4\"/g" run_o_ru.sh
    #sed -i "s/oXuRem0Mac0=[0-9,a-z][0-9,a-z]:[0-9,a-z][0-9,a-z]:[0-9,a-z][0-9,a-z]:[0-9,a-z][0-9,a-z]:[0-9,a-z][0-9,a-z]:[0-9,a-z][0-9,a-z]/oXuRem0Mac0=00:11:22:33:00:00/g" usecase_ru.cfg
    #sed -i "s/oXuRem0Mac1=[0-9,a-z][0-9,a-z]:[0-9,a-z][0-9,a-z]:[0-9,a-z][0-9,a-z]:[0-9,a-z][0-9,a-z]:[0-9,a-z][0-9,a-z]:[0-9,a-z][0-9,a-z]/oXuRem0Mac1=00:11:22:33:00:10/g" usecase_ru.cfg
    #sed -i "s/oXuRem1Mac0=[0-9,a-z][0-9,a-z]:[0-9,a-z][0-9,a-z]:[0-9,a-z][0-9,a-z]:[0-9,a-z][0-9,a-z]:[0-9,a-z][0-9,a-z]:[0-9,a-z][0-9,a-z]/oXuRem1Mac0=00:11:22:33:00:20/g" usecase_ru.cfg
    #sed -i "s/oXuRem1Mac1=[0-9,a-z][0-9,a-z]:[0-9,a-z][0-9,a-z]:[0-9,a-z][0-9,a-z]:[0-9,a-z][0-9,a-z]:[0-9,a-z][0-9,a-z]:[0-9,a-z][0-9,a-z]/oXuRem1Mac1=00:11:22:33:00:30/g" usecase_ru.cfg
#
    #echo "iovaMode=1" >> usecase_ru.cfg

    cd /home/flexran/bin/nr5g/gnb/l1/orancfg/sub6_mu1_100mhz_4x4/oru/
    #sed -i "s/0000:21:02.0/$PCIaddr1/g;s/0000:21:02.1/$PCIaddr2/g" run_o_ru.sh
    sed -i "s/vf_addr_o_xu_a \"0000:[0-9,a-z][0-9,a-z]:[0-9,a-z][0-9,a-z].[0-9],0000:[0-9,a-z][0-9,a-z]:[0-9,a-z][0-9,a-z].[0-9]\"/vf_addr_o_xu_a \"$PCIaddr1,$PCIaddr2\"/g" run_o_ru.sh
    sed -i "s/vf_addr_o_xu_b \"0000:[0-9,a-z][0-9,a-z]:[0-9,a-z][0-9,a-z].[0-9],0000:[0-9,a-z][0-9,a-z]:[0-9,a-z][0-9,a-z].[0-9]\"/vf_addr_o_xu_b \"$PCIaddr3,$PCIaddr4\"/g" run_o_ru.sh
    sed -i "s/oXuRem0Mac0=[0-9,a-z][0-9,a-z]:[0-9,a-z][0-9,a-z]:[0-9,a-z][0-9,a-z]:[0-9,a-z][0-9,a-z]:[0-9,a-z][0-9,a-z]:[0-9,a-z][0-9,a-z]/oXuRem0Mac0=00:11:22:33:00:00/g" usecase_ru.cfg
    sed -i "s/oXuRem0Mac1=[0-9,a-z][0-9,a-z]:[0-9,a-z][0-9,a-z]:[0-9,a-z][0-9,a-z]:[0-9,a-z][0-9,a-z]:[0-9,a-z][0-9,a-z]:[0-9,a-z][0-9,a-z]/oXuRem0Mac1=00:11:22:33:00:10/g" usecase_ru.cfg
    sed -i "s/oXuRem1Mac0=[0-9,a-z][0-9,a-z]:[0-9,a-z][0-9,a-z]:[0-9,a-z][0-9,a-z]:[0-9,a-z][0-9,a-z]:[0-9,a-z][0-9,a-z]:[0-9,a-z][0-9,a-z]/oXuRem1Mac0=00:11:22:33:00:20/g" usecase_ru.cfg
    sed -i "s/oXuRem1Mac1=[0-9,a-z][0-9,a-z]:[0-9,a-z][0-9,a-z]:[0-9,a-z][0-9,a-z]:[0-9,a-z][0-9,a-z]:[0-9,a-z][0-9,a-z]:[0-9,a-z][0-9,a-z]/oXuRem1Mac1=00:11:22:33:00:30/g" usecase_ru.cfg
    sed -i "s/ioCore=2/ioCore=62/g" usecase_ru.cfg
    sed -i "s/oXuEthLinkSpeed=25/oXuEthLinkSpeed=100/g" usecase_ru.cfg
    echo "iovaMode=1" >> usecase_ru.cfg


    sed -i "s/ioCore=2/ioCore=62/g" config_file_o_ru.dat
    sed -i "s/duMac0=[0-9,a-z][0-9,a-z]:[0-9,a-z][0-9,a-z]:[0-9,a-z][0-9,a-z]:[0-9,a-z][0-9,a-z]:[0-9,a-z][0-9,a-z]:[0-9,a-z][0-9,a-z]/duMac0=00:11:22:33:00:00/g" config_file_o_ru.dat
    sed -i "s/duMac1=[0-9,a-z][0-9,a-z]:[0-9,a-z][0-9,a-z]:[0-9,a-z][0-9,a-z]:[0-9,a-z][0-9,a-z]:[0-9,a-z][0-9,a-z]:[0-9,a-z][0-9,a-z]/duMac1=00:11:22:33:00:10/g" config_file_o_ru.dat
    sed -i "s/ruMac0=[0-9,a-z][0-9,a-z]:[0-9,a-z][0-9,a-z]:[0-9,a-z][0-9,a-z]:[0-9,a-z][0-9,a-z]:[0-9,a-z][0-9,a-z]:[0-9,a-z][0-9,a-z]/ruMac0=00:11:22:33:00:01/g" config_file_o_ru.dat
    sed -i "s/ruMac1=[0-9,a-z][0-9,a-z]:[0-9,a-z][0-9,a-z]:[0-9,a-z][0-9,a-z]:[0-9,a-z][0-9,a-z]:[0-9,a-z][0-9,a-z]:[0-9,a-z][0-9,a-z]/ruMac1=00:11:22:33:00:11/g" config_file_o_ru.dat

    sed -i "s/duMac2=[0-9,a-z][0-9,a-z]:[0-9,a-z][0-9,a-z]:[0-9,a-z][0-9,a-z]:[0-9,a-z][0-9,a-z]:[0-9,a-z][0-9,a-z]:[0-9,a-z][0-9,a-z]/duMac2=00:11:22:33:00:20/g" config_file_o_ru.dat
    sed -i "s/duMac3=[0-9,a-z][0-9,a-z]:[0-9,a-z][0-9,a-z]:[0-9,a-z][0-9,a-z]:[0-9,a-z][0-9,a-z]:[0-9,a-z][0-9,a-z]:[0-9,a-z][0-9,a-z]/duMac3=00:11:22:33:00:30/g" config_file_o_ru.dat
    sed -i "s/ruMac2=[0-9,a-z][0-9,a-z]:[0-9,a-z][0-9,a-z]:[0-9,a-z][0-9,a-z]:[0-9,a-z][0-9,a-z]:[0-9,a-z][0-9,a-z]:[0-9,a-z][0-9,a-z]/ruMac2=00:11:22:33:00:21/g" config_file_o_ru.dat
    sed -i "s/ruMac3=[0-9,a-z][0-9,a-z]:[0-9,a-z][0-9,a-z]:[0-9,a-z][0-9,a-z]:[0-9,a-z][0-9,a-z]:[0-9,a-z][0-9,a-z]:[0-9,a-z][0-9,a-z]/ruMac3=00:11:22:33:00:31/g" config_file_o_ru.dat

    #cd /home/flexran/bin/nr5g/gnb/l1/orancfg/mmwave_mu3_100mhz_2x2/oru/
    ##sed -i "s/0000:21:02.0/$PCIaddr1/g;s/0000:21:02.1/$PCIaddr2/g" run_o_ru.sh
    #sed -i "s/vf_addr_o_xu_a \"0000:[0-9,a-z][0-9,a-z]:[0-9,a-z][0-9,a-z].[0-9],0000:[0-9,a-z][0-9,a-z]:[0-9,a-z][0-9,a-z].[0-9]\"/vf_addr_o_xu_a \"$PCIaddr1,$PCIaddr2\"/g" run_o_ru.sh
    #sed -i "s/vf_addr_o_xu_b \"0000:[0-9,a-z][0-9,a-z]:[0-9,a-z][0-9,a-z].[0-9],0000:[0-9,a-z][0-9,a-z]:[0-9,a-z][0-9,a-z].[0-9]\"/vf_addr_o_xu_b \"$PCIaddr3,$PCIaddr4\"/g" run_o_ru.sh
    #sed -i "s/oXuRem0Mac0=[0-9,a-z][0-9,a-z]:[0-9,a-z][0-9,a-z]:[0-9,a-z][0-9,a-z]:[0-9,a-z][0-9,a-z]:[0-9,a-z][0-9,a-z]:[0-9,a-z][0-9,a-z]/oXuRem0Mac0=00:11:22:33:00:00/g" usecase_ru.cfg
    #sed -i "s/oXuRem0Mac1=[0-9,a-z][0-9,a-z]:[0-9,a-z][0-9,a-z]:[0-9,a-z][0-9,a-z]:[0-9,a-z][0-9,a-z]:[0-9,a-z][0-9,a-z]:[0-9,a-z][0-9,a-z]/oXuRem0Mac1=00:11:22:33:00:10/g" usecase_ru.cfg
    #sed -i "s/oXuRem1Mac0=[0-9,a-z][0-9,a-z]:[0-9,a-z][0-9,a-z]:[0-9,a-z][0-9,a-z]:[0-9,a-z][0-9,a-z]:[0-9,a-z][0-9,a-z]:[0-9,a-z][0-9,a-z]/oXuRem1Mac0=00:11:22:33:00:20/g" usecase_ru.cfg
    #sed -i "s/oXuRem1Mac1=[0-9,a-z][0-9,a-z]:[0-9,a-z][0-9,a-z]:[0-9,a-z][0-9,a-z]:[0-9,a-z][0-9,a-z]:[0-9,a-z][0-9,a-z]:[0-9,a-z][0-9,a-z]/oXuRem1Mac1=00:11:22:33:00:30/g" usecase_ru.cfg

    #echo "iovaMode=1" >> usecase_ru.cfg
        #open core pining
    cpulist=$(cat /sys/fs/cgroup/cpuset/cpuset.cpus)
    startd=$(echo $cpulist|sed "s/,/\n/g" | sort | sed -n "1p")
    twod=$(echo $cpulist|sed "s/,/\n/g" | sort | sed -n "2p")
    if [ -z $startd ] ; then
      echo "cpuset is empty"
      exit 0
    fi
    startd_f=$(echo $startd|awk -F '-' '{print $1}')
    startd_e=$(echo $startd|awk -F '-' '{print $2}')
    #echo "startd_f:$startd_f,start_e:$startd_e"
    start_n=$(expr $startd_e - $startd_f)
    if [ $start_n -gt 20 ] ; then
      exit 0
    fi

    twod_f=$(echo $twod|sed "s/-/\n/g" | sort | sed -n "1p")
    twod_e=$(echo $twod|sed "s/-/\n/g" | sort | sed -n "2p")
    #start_n=`expr $startd_e - $startd_f`
    twod_n=$(expr $twod_e - $twod_f)

    systemcore=$twod_f
    maincore=$(expr $twod_f + 1)
    iocore=$(expr $twod_f + 2)
    ioworkcore=$(expr $twod_f + 3)

    dec2hex(){
      printf "%x" $1
    }
    a1=$((1<<$ioworkcore))
    b1=$(dec2hex $a1)

    cd /home/flexran/bin/nr5g/gnb/l1/orancfg/sub3_mu0_10mhz_4x4/oru/
    sed -i "s/ioWorker=0x8/ioWorker=0x$b1/g" usecase_ru.cfg
    sed -i "s/ioCore=2/ioCore=$iocore/g" usecase_ru.cfg
    echo "mainCore=$maincore" >> usecase_ru.cfg
    echo "systemCore=$systemcore" >> usecase_ru.cfg

    cd /home/flexran/bin/nr5g/gnb/l1/orancfg/sub3_mu0_20mhz_4x4/oru/
    sed -i "s/ioWorker=0x8/ioWorker=0x$b1/g" usecase_ru.cfg
    sed -i "s/ioCore=2/ioCore=$iocore/g" usecase_ru.cfg
    echo "mainCore=$maincore" >> usecase_ru.cfg
    echo "systemCore=$systemcore" >> usecase_ru.cfg

    #cd /home/flexran/bin/nr5g/gnb/l1/orancfg/sub3_mu0_20mhz_sub3_mu1_20mhz_4x4/oru/
    #sed -i "s/ioWorker=0x8/ioWorker=0x$b1/g" usecase_ru.cfg
    #sed -i "s/ioCore=2/ioCore=$iocore/g" usecase_ru.cfg
    #echo "mainCore=$maincore" >> usecase_ru.cfg
    #echo "systemCore=$systemcore" >> usecase_ru.cfg
#
    #cd /home/flexran/bin/nr5g/gnb/l1/orancfg/sub3_mu0_20mhz_sub6_mu1_100mhz_4x4/oru/
    #sed -i "s/ioWorker=0x8/ioWorker=0x$b1/g" usecase_ru.cfg
    #sed -i "s/ioCore=2/ioCore=$iocore/g" usecase_ru.cfg
    #echo "mainCore=$maincore" >> usecase_ru.cfg
    #echo "systemCore=$systemcore" >> usecase_ru.cfg

    cd /home/flexran/bin/nr5g/gnb/l1/orancfg/sub6_mu1_100mhz_4x4/oru/
    sed -i "s/ioWorker=0x8/ioWorker=0x$b1/g" usecase_ru.cfg
    sed -i "s/ioCore=2/ioCore=$iocore/g" usecase_ru.cfg
    echo "mainCore=$maincore" >> usecase_ru.cfg
    echo "systemCore=$systemcore" >> usecase_ru.cfg

    #cd /home/flexran/bin/nr5g/gnb/l1/orancfg/mmwave_mu3_100mhz_2x2/oru/
    #sed -i "s/ioWorker=0x8/ioWorker=0x$b1/g" usecase_ru.cfg
    #sed -i "s/ioCore=2/ioCore=$iocore/g" usecase_ru.cfg
    #echo "mainCore=$maincore" >> usecase_ru.cfg
    #echo "systemCore=$systemcore" >> usecase_ru.cfg
  fi
fi

if [ $test_mode = "timer" ]; then
  if [ -n "$PCIDEVICE_INTEL_COM_INTEL_FEC_5G" ]; then
    cd /home/flexran/bin/nr5g/gnb/l1/
    #sed -i "s/0000:1f:00.1/$PCIDEVICE_INTEL_COM_INTEL_FEC_5G/g" phycfg_timer.xml
    sed -i "s/dpdkBasebandDevice>0000:[0-9,a-z][0-9,a-z]:[0-9,a-z][0-9,a-z].[0-9]<\/dpdkBasebandDevice/dpdkBasebandDevice>$PCIDEVICE_INTEL_COM_INTEL_FEC_5G<\/dpdkBasebandDevice/g" phycfg_timer.xml
    sed -i "s/<dpdkBasebandFecMode>0<\/dpdkBasebandFecMode>/<dpdkBasebandFecMode>1<\/dpdkBasebandFecMode>/g" phycfg_timer.xml
    sed -i "s/<dpdkIovaMode>0<\/dpdkIovaMode>/<dpdkIovaMode>1<\/dpdkIovaMode>/g" phycfg_timer.xml
    cpulist=`cat /sys/fs/cgroup/cpuset/cpuset.cpus`

    echo "$cpulist" > /home/flexran/tests/cpulist.txt

    startd=$(echo $cpulist|sed "s/,/\n/g" | sort | sed -n "1p")
    twod=$(echo $cpulist|sed "s/,/\n/g" | sort | sed -n "2p")
    if [ -z $startd ] ; then
      echo "cpuset is empty"
      exit 0
    fi
    startd_f=$(echo $startd|awk -F '-' '{print $1}')
    startd_e=$(echo $startd|awk -F '-' '{print $2}')
    #echo "startd_f:$startd_f,start_e:$startd_e"
    start_n=$(expr $startd_e - $startd_f)
    if [ $start_n -gt 20 ] ; then
      exit 0
    fi

    twod_f=$(echo $twod|sed "s/-/\n/g" | sort | sed -n "1p")
    twod_e=$(echo $twod|sed "s/-/\n/g" | sort | sed -n "2p")
    #start_n=`expr $startd_e - $startd_f`
    twod_n=$(expr $twod_e - $twod_f)

    systemthread=$twod_f
    timerThread=$(expr $twod_f + 1)
    FpgaDriverCpuInfo=$(expr $twod_f + 2)
    FrontHaulCpuInfo=$(expr $twod_f + 2)
    radioDpdkMaster=$(expr $twod_f + 1)

    file=/home/flexran/bin/nr5g/gnb/l1/phycfg_timer.xml
    sed -i "s/<systemThread>0, 0, 0<\/systemThread>/<systemThread>$systemthread, 0, 0<\/systemThread>/g" $file
    sed -i "s/<timerThread>2, 96, 0<\/timerThread>/<timerThread>$timerThread, 96, 0<\/timerThread>/g" $file
    sed -i "s/<FpgaDriverCpuInfo>3, 96, 0<\/FpgaDriverCpuInfo>/<FpgaDriverCpuInfo>$FpgaDriverCpuInfo, 96, 0<\/FpgaDriverCpuInfo>/g" $file
    sed -i "s/<FrontHaulCpuInfo>3, 96, 0<\/FrontHaulCpuInfo>/<FrontHaulCpuInfo>$FrontHaulCpuInfo, 96, 0<\/FrontHaulCpuInfo>/g" $file
    sed -i "s/<radioDpdkMaster>2, 99, 0<\/radioDpdkMaster>/<radioDpdkMaster>$radioDpdkMaster, 99, 0<\/radioDpdkMaster>/g" $file

  fi

  if [ -z "$PCIDEVICE_INTEL_COM_INTEL_FEC_5G" ]; then
    testmaccfg_file=/home/flexran/bin/nr5g/gnb/testmac/testmac_cfg.xml
    sed -i "s/<dpdkIovaMode>0<\/dpdkIovaMode>/<dpdkIovaMode>1<\/dpdkIovaMode>/g" $testmaccfg_file
    sed -i "s/<PhyCoreCheck>1<\/PhyCoreCheck>/<PhyCoreCheck>0<\/PhyCoreCheck>/g" $testmaccfg_file
    sed -i "s/1000000010/11000000110/g" /home/flexran/bin/nr5g/gnb/testmac/icelake-sp/icxsp_mu1_100mhz_4x4_hton.cfg
    sed -i "s/1f8000001f0/ff0000f0/g" /home/flexran/bin/nr5g/gnb/testmac/icelake-sp/icxsp_mu1_100mhz_4x4_hton.cfg

    cd /home/flexran/bin/nr5g/gnb/testmac/icelake-sp/
    cat icxsp_mu0_10mhz_4x4_hton.cfg > icxsp.cfg
    cat icxsp_mu0_20mhz_4x4_hton.cfg >> icxsp.cfg
    cat icxsp_mu1_100mhz_4x4_hton.cfg >> icxsp.cfg

    cpulist=$(cat /sys/fs/cgroup/cpuset/cpuset.cpus)
    start_f=$(echo $cpulist|sed "s/,/\n/g" | sort | sed -n "1p")
    end_f=$(echo $cpulist|sed "s/,/\n/g" | sort | sed -n "2p")
    if [ -z $cpulist ] ; then
      echo "cpuset is empty"
      exit 0
    fi
    #echo "start:$start_f,end:$end_f"
    if [ -z $end_f ]; then
      start_f=$(echo $cpulist|sed "s/-/\n/g" | sort | sed -n "1p")
      end_f=$(echo $cpulist|sed "s/-/\n/g" | sort | sed -n "2p")
      init_list=$(expr $end_f - $start_f)
      if [ $init_list -gt 20 ] ; then
        exit 0
      fi
    fi
    #testmaccfg_file=/home/flexran/bin/nr5g/gnb/testmac/testmac_cfg.xml
    sed -i "s/<systemThread>0, 0, 0<\/systemThread>/<systemThread>$start_f, 0, 0<\/systemThread>/g" $testmaccfg_file
    sed -i "s/<runThread>0, 89, 0<\/runThread>/<runThread>$start_f, 89, 0<\/runThread>/g" $testmaccfg_file
    sed -i "s/<wlsRxThread>1, 90, 0<\/wlsRxThread>/<wlsRxThread>$end_f, 90, 0<\/wlsRxThread>/g" $testmaccfg_file

    work_cpulist=$(cat /home/flexran/tests/cpulist.txt)
    startd=$(echo $work_cpulist|sed "s/,/\n/g" | sort | sed -n "1p")
    startd2=$(echo $work_cpulist|sed "s/,/\n/g" | sort | sed -n "2p")
    startd_f=$(echo $startd|awk -F '-' '{print $1}')
    startd_e=$(echo $startd|awk -F '-' '{print $2}')
    startd2_f=$(echo $startd2|awk -F '-' '{print $1}')
    startd2_e=$(echo $startd2|awk -F '-' '{print $2}')
    #startd_e=`echo $startd|sed "s/-/\n/g" | sort | sed -n "2p"`
    start_n=$(expr $startd_e - $startd_f)

    dec2hex(){
      printf "%x" $1
    }
    #a=$(dec2hex 55)
    #a=`echo "ibase=10;obase=16;8"`
    startd_f1=$(expr $startd_f + 1)
    startd_f2=$(expr $startd_f + 2)
    startd_f3=$(expr $startd_f + 3)
    startd_f4=$(expr $startd_f + 4)
    startd_f5=$(expr $startd_f + 5)
    startd_f6=$(expr $startd_f + 6)
    startd_f7=$(expr $startd_f + 7)
    startd_f8=$(expr $startd_f + 8)
    startd_f9=$(expr $startd_f + 9)
    startd_f10=$(expr $startd_f + 10)
    startd_f11=$(expr $startd_f + 11)

    #startd2_f1=`expr $startd2_f + 4`
    #startd2_f2=`expr $startd2_f + 5`
    #startd2_f3=`expr $startd2_f + 6`

    if [ $start_n -lt 8 ] ; then
      echo "configure cpu failed, Please modify the parameters manually"
      exit 0
    fi

    a6=$((1<<$startd_f | 1 << $startd_f1 | 1 << $startd_f2 | 1 << $startd_f3 | 1<<$startd_f4 | 1<<$startd_f5))
    b6=$(dec2hex $a6)
    a2=$((1<<$startd_f | 1 << $startd_f1))
    b2=$(dec2hex $a2)

    a3=$((1<<$startd_f | 1 << $startd_f1 | 1 << $startd_f2))
    b3=$(dec2hex $a3)
    a5=$((1<<$startd_f | 1 << $startd_f1 | 1 << $startd_f2 | 1 << $startd_f3 | 1<<$startd_f4 ))
    b5=$(dec2hex $a5)
    a4=$((1<<$startd_f | 1 << $startd_f1 | 1 << $startd_f2 | 1 << $startd_f3))
    b4=$(dec2hex $a4)
    a12=$((1<<$startd_f | 1 << $startd_f1 | 1 << $startd_f2 | 1 << $startd_f3 | 1<<$startd_f4 | 1<<$startd_f5 | 1 << $startd_f6 | 1<<$startd_f7 | 1<<$startd_f8 |1 << $startd_f9 | 1<<$startd_f10 | 1<<$startd_f11 ))
    b12=$(dec2hex $a12)

    #aa=$((1<< $startd2_f1 | 1<<$startd2_f2 | 1<<$startd2_f3))
    #bb=$(dec2hex $aa)
    #ll=`echo "$b12"|wc -L`
    #len=`expr 16 - $ll`
    #key=""
    #for ((i=1;i<=$len;i++))
    #do
    #  key="${key}0"
    #done
    #keyd="$bb$key$b12"
    #echo "keyd:$keyd"


    a8=$((1<<$startd_f | 1 << $startd_f1 | 1 << $startd_f2 | 1 << $startd_f3 | 1<<$startd_f4 | 1<<$startd_f5 | 1 << $startd_f6 | 1<<$startd_f7))
    b8=$(dec2hex $a8)
    #echo "0x$b"
    testmacfile=/home/flexran/bin/nr5g/gnb/testmac/cascade_lake-sp/clxsp_mu0_10mhz_4x4_hton.cfg
    sed -i "s/3f0003f0/$b6/g" $testmacfile
    sed -i "s/f0000000f0/$b6/g" /home/flexran/bin/nr5g/gnb/testmac/icelake-sp/icxsp_mu0_10mhz_4x4_hton.cfg
    sed -i "s/1000000010/$b2/g" /home/flexran/bin/nr5g/gnb/testmac/icelake-sp/icxsp_mu0_20mhz_4x4_hton.cfg
    sed -i "s/3800000030/$b5/g" /home/flexran/bin/nr5g/gnb/testmac/icelake-sp/icxsp_mu0_20mhz_4x4_hton.cfg
    sed -i "s/3000000030/$b4/g" /home/flexran/bin/nr5g/gnb/testmac/icelake-sp/icxsp_mu0_20mhz_4x4_hton.cfg
    sed -i "s/3f0000003f0/$b12/g" /home/flexran/bin/nr5g/gnb/testmac/icelake-sp/icxsp_mu0_20mhz_4x4_hton.cfg

    sed -i "s/11000000110/$b4/g" /home/flexran/bin/nr5g/gnb/testmac/icelake-sp/icxsp_mu1_100mhz_4x4_hton.cfg
    sed -i "s/3800000030/$b5/g" /home/flexran/bin/nr5g/gnb/testmac/icelake-sp/icxsp_mu1_100mhz_4x4_hton.cfg
    sed -i "s/1800000010/$b3/g" /home/flexran/bin/nr5g/gnb/testmac/icelake-sp/icxsp_mu1_100mhz_4x4_hton.cfg
    sed -i "s/ff0000f0/$b12/g" /home/flexran/bin/nr5g/gnb/testmac/icelake-sp/icxsp_mu1_100mhz_4x4_hton.cfg
    sed -i "s/07000000070/$b6/g" /home/flexran/bin/nr5g/gnb/testmac/icelake-sp/icxsp_mu1_100mhz_4x4_hton.cfg

    sed -i "s/1000000010/$b2/g" /home/flexran/bin/nr5g/gnb/testmac/icelake-sp/icxsp_mu3_100mhz_2x2_hton.cfg
    sed -i "s/3000000030/$b4/g" /home/flexran/bin/nr5g/gnb/testmac/icelake-sp/icxsp_mu3_100mhz_2x2_hton.cfg
    sed -i "s/7000000070/$b6/g" /home/flexran/bin/nr5g/gnb/testmac/icelake-sp/icxsp_mu3_100mhz_2x2_hton.cfg
    sed -i "s/f0000000f0/$b8/g" /home/flexran/bin/nr5g/gnb/testmac/icelake-sp/icxsp_mu3_100mhz_2x2_hton.cfg

    cd /home/flexran/bin/nr5g/gnb/testmac/icelake-sp/
    cat icxsp_mu0_10mhz_4x4_hton.cfg > icxsp.cfg
    cat icxsp_mu0_20mhz_4x4_hton.cfg >> icxsp.cfg
    cat icxsp_mu1_100mhz_4x4_hton.cfg >> icxsp.cfg

  fi

fi

