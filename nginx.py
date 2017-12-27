#!/usr/bin/env python
# coding: utf-8

###################################
# User:chengang                   #
# Email:aguncn@163.com    #
# Date:2016-02-25                 #
###################################

import time
import datetime
import sys
import os
import os.path
import re
import json
  

class NginxLog(object):
    
    def __init__(self, log_file, interface_list, seek_file):
        self.log_file = log_file
        self.interface_list = interface_list
        self.seek_file = seek_file

    # 将输出编码成json格式
    def jsonFormat(self, python_data):
        json_data = json.dumps(python_data, indent=2)
        return json_data

    # 获取电脑主机名
	# Linux 操作系统 os.name 输出'posix'  Windows 操作系统输出'nt'
    def hostname(self):
        sys = os.name
        if sys == 'nt':
            hostname = os.getenv('computername')
            return hostname
        elif sys == 'posix':
            host = os.popen('echo $HOSTNAME')
            try:
                hostname = host.read()
                return hostname
            finally:
                host.close()
        else:
            return 'Unkwon hostname'


    # 将读过的文件游标写入临时文件
    def writeSeek(self, seek):
        with open(self.seek_file,'w') as f:
            f.write(time.strftime("%Y-%m-%d %H:%M:%S", time.localtime(time.time()))+"\n")
            f.write(str(seek)+"\n")
            
    # 读出新生成的日志条目
    def LogRead(self):
        # 如果第一次运行，或是删除临时文件，从头运行，否则，从上次读取之后运行
        # 0代表从头开始，1代表当前位置，2代表文件最末尾位置。
        if os.path.exists(self.seek_file):
            with open(self.seek_file) as f:
                seek_tmp = f.readlines()
            seek_old = int(seek_tmp[1].strip())
        else:
            seek_old = 0
        with open(self.log_file) as f:
            #记录当前最新文件游标
            f.seek(0,2)
            seek_now = f.tell()
            # 读取上次读完之后的日志条目
            if seek_now >= seek_old:
                f.seek(seek_old,0)
                chunk = f.read(seek_now-seek_old)
                # 也可以考虑用xreadlines来实现
                # for line in f.xreadlines():
                #    pass # do something
            # 如果文件游标倒退，说明日志文件已轮循，从头开始
            else:
                f.seek(0,0)
                chunk = f.read(seek_now)
        # 将这次的游标写入临时文件  
        # self.writeSeek(seek_now)
        return chunk
            
    def LogStatistics(self):
        #分析NGINX日志的正则表达示，如果日志格式更改，则需要相应作更改
        #我拿到的日志样本和鹏龙的不一样，所以注释了一个字段
        #field 0
        field_remote_addr = r"?P<l_remote_addr>.*"
        #field 1
        field_remote_user = r"?P<l_remote_user>-"
        #field 2
        field_time_local = r"?P<l_time_local>\[.*\]"
        #field 3
        field_request = r"?P<l_request>\"[^\"]*\""
        #field 4
        field_status = r"?P<l_status>\"[^\"]*\""
        #field 5
        field_body_bytes_sent = r"?P<l_body_bytes_sent>\d+"
        #field 6
        field_http_refere = r"?P<l_http_refere>\"[^\"]*\""
        #field 7
        field_http_user_agent = r"?P<l_http_user_agent>\"[^\"]*\""
        #field 8
        #field_http_x_fowarded_for = r"?P<l_http_x_fowarded_for>\"[^\"]*\""
        #field 8
        field_all_cookie = r"?P<l_all_cookie>\"[^\"]*\""
        #field 9
        field_gzip_ratio = r"?P<l_gzip_ratio>\"[^\"]*\""
        #field 10
        field_upstream_addr = r"?P<l_upstream_addr>.*"
        #field 11
        field_bytes_sent = r"?P<l_bytes_sent>\d+"
        #field 12
        field_request_length = r"?P<l_request_length>\d+"
        #field 13
        field_request_time = r"?P<l_request_time>.*"

        #以下为样例，方便调试
        '''
        10.25.162.22 - - [24/Feb/2016:14:09:25 +0800] "GET / HTTP/1.0" "200" 612 "-" 

        "-" "-" "-" - 846 54 0.000
        10.25.162.22 - - [24/Feb/2016:14:09:35 +0800] "GET 

        /dsf/getRealTimeDatas?codes=&codeTypes=&_v=14562941753244588 

        HTTP/1.0" "200" 37 

        "http://asfdte/quote/dsftml" "Mozilla/5.0 

        (iPhone; CPU iPhone OS 8_0 like Mac OS X) AppleWebKit/600.1.3 (KHTML, like 

        Gecko) Version/8.0 Mobile/12A4345d Safari/600.1.4" "-" "-" 10.25.174.34:30077 
862 0.002
        '''
        # 正则匹配字段
        nginxlog_pattern = re.compile(r"(%s)\s-\s(%s)\s(%s)\s(%s)\s(%s)\s(%s)\s(%s)\s(%s)\s(%s)\s(%s)\s(%s)\s(%s)\s(%s)\s(%s)" \
                                      %(field_remote_addr,field_remote_user,field_time_local,field_request,field_status, \
                                        field_body_bytes_sent,field_http_refere,field_http_user_agent, \
                                        field_all_cookie,field_gzip_ratio,field_upstream_addr,field_bytes_sent,field_request_length, \
                                        field_request_time),re.VERBOSE)
        #输出结果
        result_list = []
        # 未启用字段，作占位用
        time_ns =  datetime.datetime.now().microsecond
        #转换成符合要求的时间秒格式
        time_stamp = int(str(time.time())[0:10])
        host_name = self.hostname()
        # 多少个URL，就要循环读取多少次，算法粗糙，后面再想办法吧，因为如果只循环一次文件读取，则在里面要循环列表，还难理顺思路
        for interface_item in self.interface_list:
            # json格式样例 {"ns":470464001,"clock":1450368176,"value":"1","key":"macs.func.exeCount_0ms_50ms[104_202]","host":"SQSZ-L4"},
            # 构造符合要求的字典
            interface_item_dict_count = {}
            interface_item_dict_avg_request_time = {}
            interface_item_dict_2xx = {}
            interface_item_dict_4xx = {}
            interface_item_dict_5xx = {}
            interface_item_dict_count['ns']=interface_item_dict_avg_request_time['ns']=interface_item_dict_2xx['ns']=interface_item_dict_4xx['ns']=interface_item_dict_5xx['ns']=time_ns
            interface_item_dict_count['clock']=interface_item_dict_avg_request_time['clock']=interface_item_dict_2xx['clock']=interface_item_dict_4xx['clock']=interface_item_dict_5xx['clock']=time_stamp
            interface_item_dict_count['host']=interface_item_dict_avg_request_time['host']=interface_item_dict_2xx['host']=interface_item_dict_4xx['host']=interface_item_dict_5xx['host']=host_name
            interface_item_dict_count['key'] = interface_item + '_count'
            interface_item_dict_count['value'] = 0
            interface_item_dict_avg_request_time['key'] = interface_item + '_avg_request_time'
            interface_item_dict_avg_request_time['value'] = 0
            interface_item_dict_2xx['key'] = interface_item + '_2xx'
            interface_item_dict_2xx['value'] = 0
            interface_item_dict_4xx['key'] = interface_item + '_4xx'
            interface_item_dict_4xx['value'] = 0
            interface_item_dict_5xx['key'] = interface_item + '_5xx'
            interface_item_dict_5xx['value'] = 0
            hit_url_count = 0
            for line in self.LogRead().split('\n'):
                line_matchs = nginxlog_pattern.match(line)
                if line_matchs!=None:
                    #匹配字段
                    allGroups = line_matchs.groups()
                    remote_addr = allGroups[0]
                    #切割出真正的URL
                    request_url = allGroups[3].split()[1].split('?')[0].split('/')[-1]
                    status_code = allGroups[4]
                    request_time = allGroups[13]
                    # 匹配URL之后进行数据结构操作
                    if interface_item == request_url:
                        hit_url_count += 1
                        interface_item_dict_count['value'] += 1
                        interface_item_dict_avg_request_time['value'] += float(request_time)
                        if status_code.strip('\"').startswith('2'):
                            interface_item_dict_2xx['value'] += 1
                        if status_code.strip('\"').startswith('4'):
                            interface_item_dict_4xx['value'] += 1
                        if status_code.strip('\"').startswith('5'):
                            interface_item_dict_5xx['value'] += 1
            # 求平均请求反应时间
            if interface_item_dict_avg_request_time['value'] != 0:
                interface_item_dict_avg_request_time['value'] = interface_item_dict_avg_request_time['value'] / hit_url_count
    
            #入总列表
            result_list.append(interface_item_dict_count)
            result_list.append(interface_item_dict_avg_request_time)
            result_list.append(interface_item_dict_2xx)
            result_list.append(interface_item_dict_4xx)
            result_list.append(interface_item_dict_5xx)
        return self.jsonFormat(result_list)

        
    def resultOutput(self):
        pass

def main():
    #需要收集的url    
    interface_list = ['getIndexData', \
                      'getRealTimeDatas',
                      'hehel',]
    #日志定位
    log_file  = 'd:\\demo\\sample.log'
    # 临时文件游标文件
    seek_file = 'd:\\demo\\log_check_seek.tmp'
    
    nginx_log = NginxLog(log_file, interface_list, seek_file)
    return_json_data = nginx_log.LogStatistics()
    print return_json_data

if __name__ == "__main__":
    main()