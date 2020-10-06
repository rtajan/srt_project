

Pour encoder le fichier ```votre_video.avi``` à l'aide de VLC :
````
cvlc -vvv votre_video.avi --sout="#transcode{vcodec=h264,vb=100}:standard{access=file,mux=ts,dst=votre_fichier_ts.ts}"
````
