#!/bin/bash
name=($(mysql -D camera -h 125.253.123.9 -ucamera -pHNNcamera@2014 -Bse "select w_name from tbl_camera where camera_process IS NOT NULL"))
# count=$(mysql -D camera -h 125.253.123.9 -ucamera -pHNNcamera@2014 -Bse "select count(*) from tbl_camera where camera_process IS NOT NULL")
# echo $name
count=${#name[@]}
# echo $count
restartcmd()
{	
  	info=$(mysql -D camera -h 125.253.123.9 -ucamera -pHNNcamera@2014 -Bse "select username, password, ip, port, type, node_ip from tbl_camera where w_name = '$1' and camera_process is not null")
  	options=$(mysql -D camera -h 125.253.123.9 -ucamera -pHNNcamera@2014 -Bse "select options from tbl_camera where w_name = '$1' and camera_process is not null")
  	options=($options)
  	info=($info)
  	cmd="/tmp/ffmpeg2/ffmpeg -rtsp_transport tcp -i rtsp://${info[0]}:${info[1]}@${info[2]}:${info[3]}/${info[4]} ${options[@]} -f flv -threads 2 rtmp://127.0.0.1:1935/RTMP/$1 </dev/null > /dev/null 2>&1 &"
  	eval $cmd
}
update()
{
	mysql -D camera -h 125.253.123.9 -ucamera -pHNNcamera@2014 -Bse "UPDATE tbl_camera SET camera_process = $1 where w_name = '$2' and camera_process is not null"
}
i=0
while [[ i -lt count ]]; do
	echo ${name[i]}
	path="/tmp/hlslive/${name[i]}.m3u8"
	echo $path
	if [ -f $path ]; then
		current=`date +%s`
		last_mod=`stat -c "%Y" $path`
		if [[ $(($current-$last_mod)) -gt 50 ]]; then
			pid=`ps aux | grep rtsp | grep ${name[i]} | awk '{print $2}'`
			# echo $pid
			if [ ! -z "$pid" ]; then
				kill -9 $pid
				restartcmd ${name[i]}
				pid=`ps aux | grep rtsp | grep ${name[i]} | awk '{print $2}'`
				# echo $pid
				# update $pid ${name[i]}
			else
				# echo $pid
				restartcmd ${name[i]}
				pid=`ps aux | grep rtsp | grep ${name[i]} | awk '{print $2}'`
				# echo $pid
				update $pid ${name[i]}
			fi
		else
			pid=`ps aux | grep rtsp | grep ${name[i]} | awk '{print $2}'`
			piddb=$(mysql -D camera -h 125.253.123.9 -ucamera -pHNNcamera@2014 -Bse "select camera_process from tbl_camera where w_name = '${name[i]}' and camera_process is not null")
			echo "pid lay tren host $pid"
			echo $piddb
			if [[ "$pid" -ne "$piddb" ]]; then
				echo "updating"
				update $pid ${name[i]}
			fi
		fi
		echo $path exist
	else
		echo $path not exist
		pid=`ps aux | grep rtsp | grep ${name[i]} | awk '{print $2}'`
		# echo $pid
		if [ ! -z "$pid" ]; then
			kill -9 $pid
			restartcmd ${name[i]}
			pid=`ps aux | grep rtsp | grep ${name[i]} | awk '{print $2}'`
			# echo $pid
			# update $pid ${name[i]}
		else
			restartcmd ${name[i]}
			pid=`ps aux | grep rtsp | grep ${name[i]} | awk '{print $2}'`
			# echo $pid
			# update $pid ${name[i]}
		fi
	fi
	((i++))
done