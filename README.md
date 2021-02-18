# UDP2HDMI

HDMI出力回路を搭載したネットワークインタフェース.

## Description
RealSenseで取得した画像をUDPでFPGAへ送信し,FPGAからHDMIで直接モニタへ出力するシステム.  
"rs_udpClient.py"は1台のFPGAに対して画像を送信する.  
"rs_synthesis.py"は2台のFPGAに対して画像を送信する.

## Install
$git clone https://...  
Launch vivado  
$cd /PATH  
$source ./create_project.tcl  
or  
Tools > Run Tcl Script...  
Open "create_project.tcl"  

## Usage
