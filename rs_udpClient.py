# -*- coding: utf-8 -*-

#-------------------------
# RealSenseデータをUDPで送信
#-------------------------

from socket import *
import pyrealsense2 as rs
import numpy as np
import cv2
import sys
import time

if __name__ == "__main__":
    # socket
    HOST = ''
    PORT = 5000
    ADDRESS = '172.31.210.160'   # 相手

    sock = socket(AF_INET, SOCK_DGRAM)
    # ストリーム(Color)の設定
    config = rs.config()
    config.enable_stream(rs.stream.color, 640, 480, rs.format.bgr8, 30)

    # ストリーミング開始
    pipeline = rs.pipeline()
    profile = pipeline.start(config)
    print("---start---")

    while 1:
        # フレーム待ち(Color & Depth)
        frames = pipeline.wait_for_frames()
        color_frame = frames.get_color_frame()
        if not color_frame:
            continue
        img = np.asanyarray(color_frame.get_data())
        img = img.tostring()    # numpy行列からバイトデータに変換
        # 送信
        for i in range(640):
            sock.sendto(img[480*3*i:480*3*(i+1)], (ADDRESS, PORT))
        k = cv2.waitKey(1)

    # ストリーミング停止
    pipeline.stop()
    sock.close()
    cv2.destroyAllWindows() # 作成したウィンドウを破棄