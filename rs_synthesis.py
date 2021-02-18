# -*- coding: utf-8 -*-

#-------------------------
# RealSenseデータを複数のFPGAへUDPで送信
#-------------------------

from socket import *
import pyrealsense2 as rs
import numpy as np
import cv2
import sys
import time
from PIL import Image

if __name__ == "__main__":
    # socket
    HOST = ''
    PORT = 5000
    ADDRESS0 = '172.31.210.160'   # 相手
    ADDRESS1 = '172.31.210.161'   # 相手

    sock = socket(AF_INET, SOCK_DGRAM)
    # ストリーム(Color)の設定
    config = rs.config()
    config.enable_stream(rs.stream.color, 1280, 720, rs.format.bgr8, 30)

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
        # cut image
        img0 = img[0:480, 0:640]
        img1 = img[0:480, 640:1280]
        # numpy行列からバイトデータに変換
        img0 = img0.tostring()
        img1 = img1.tostring()
        # 送信
        for i in range(640):
            sock.sendto(img0[1440*i:1440*(i+1)], (ADDRESS0, PORT))
        k = cv2.waitKey(1)

        for i in range(640):
            sock.sendto(img1[1440*i:1440*(i+1)], (ADDRESS1, PORT))
        k = cv2.waitKey(1)

    # ストリーミング停止
    pipeline.stop()
    sock.close()
    cv2.destroyAllWindows() # 作成したウィンドウを破棄