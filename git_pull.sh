
2
3
4
5
6
7
8
9
10
11
12
13
14
15
16
17
18
19
20
21
22
23
24
25
26
27
28
29
30
31
32
33
34
35
36
37
38
39
40
41
42
43
44
45
46
47
48
49
50
51
52
53
54
55
56
57
58
59
60
61
62
63
64
65
66
67
68
69
70
71
72
73
74
75
76
77
78
79
80
81
82
83
84
85
86
87
88
89
90
91
92
93
94
95
96
97
98
99
100
101
102
103
104
105
106
107
108
109
110
111
112
113
114
115
116
117
118
119
120
121
122
123
124
125
126
127
128
129
130
131
132
133
134
135
136
137
138
139
140
141
142
143
144
145
146
147
148
149
150
151
152
153
154
155
156
157
158
159
160
161
162
163
164
165
166
167
168
169
170
171
172
173
174
175
176
177
178
179
180
181
182
183
184
185
186
187
188
189
190
191
192
193
194
195
196
197
198
199
200
201
202
203
204
205
206
207
208
209
210
211
212
213
214
215
216
217
218
219
220
221
222
223
224
225
226
227
228
229
230
231
232
233
234
235
236
237
238
239
240
241
242
243
244
245
246
247
248
249
250
251
252
253
254
255
256
257
258
259
260
261
262
263
264
265
266
267
268
269
270
271
272
273
274
275
276
277
278
279
280
281
282
283
284
285
286
287
288
289
290
291
292
293
294
295
296
297
298
299
300
301
302
303
304
305
306
307
308
309
310
311
312
313
314
315
316
317
318
319
320
321
322
323
324
325
326
327
328
329
330
331
332
333
334
335
336
337
338
339
340
341
342
343
344
345
346
347
348
349
350
351
352
353
354
355
356
357
358
359
360
361
362
363
364
365
366
367
368
369
370
371
372
#!/usr/bin/env bash

## 文件路径、脚本网址、文件版本以及各种环境的判断
ShellDir=${JD_DIR:-$(cd $(dirname $0); pwd)}
[[ ${JD_DIR} ]] && ShellJd=jd || ShellJd=${ShellDir}/jd.sh
LogDir=${ShellDir}/log
[ ! -d ${LogDir} ] && mkdir -p ${LogDir}
ScriptsDir=${ShellDir}/scripts
Scripts2Dir=${ShellDir}/scripts2
ConfigDir=${ShellDir}/config
FileConf=${ConfigDir}/config.sh
FileDiy=${ConfigDir}/diy.sh
FileConfSample=${ShellDir}/sample/config.sh.sample
ListCron=${ConfigDir}/crontab.list
ListCronLxk=${ScriptsDir}/docker/crontab_list.sh
ListCronShylocks=${Scripts2Dir}/docker/crontab_list.sh
ListTask=${LogDir}/task.list
ListJs=${LogDir}/js.list
ListJsAdd=${LogDir}/js-add.list
ListJsDrop=${LogDir}/js-drop.list
ContentVersion=${ShellDir}/version
ContentNewTask=${ShellDir}/new_task
ContentDropTask=${ShellDir}/drop_task
SendCount=${ShellDir}/send_count
isTermux=${ANDROID_RUNTIME_ROOT}${ANDROID_ROOT}
ShellURL=https://gitee.com/djxiao71/dj77.git
ScriptsURL=git@gitee.com:djxiao71/jd_scripts.git

## 更新crontab，gitee服务器同一时间限制5个链接，因此每个人更新代码必须错开时间，每次执行git_pull随机生成。
## 每天次数随机，更新时间随机，更新秒数随机，至少6次，至多12次，大部分为8-10次，符合正态分布。
function Update_Cron {
  if [ -f ${ListCron} ]; then
    RanMin=$((${RANDOM} % 60))
    RanSleep=$((${RANDOM} % 56))
    RanHourArray[0]=$((${RANDOM} % 3))
    for ((i=1; i<14; i++)); do
      j=$(($i - 1))
      tmp=$((${RANDOM} % 3 + ${RanHourArray[j]} + 2))
      [[ ${tmp} -lt 24 ]] && RanHourArray[i]=${tmp} || break
    done
    RanHour=${RanHourArray[0]}
    for ((i=1; i<${#RanHourArray[*]}; i++)); do
      RanHour="${RanHour},${RanHourArray[i]}"
    done
    perl -i -pe "s|.+(bash.+git_pull.+log.*)|${RanMin} ${RanHour} \* \* \* sleep ${RanSleep} && \1|" ${ListCron}
    crontab ${ListCron}
  fi
}

## 更新shell
function Git_PullShell {
  echo -e "更新shell...\n"
  cd ${ShellDir}
  git fetch --all
  ExitStatusShell=$?
  git reset --hard origin/main
  wget -q --no-check-certificate https://ghproxy.com/https://raw.githubusercontent.com/wuzhi-docker1/jd-base/main/sample/config.sh.sample -O ${FileConfSample}
  echo
}

## 克隆scripts
function Git_CloneScripts {
  echo -e "克隆scripts...\n"
  git clone -b master ${ScriptsURL} ${ScriptsDir}
  ExitStatusScripts=$?
  echo
}

## 更新scripts
function Git_PullScripts {
  echo -e "更新scripts...\n"
  cd ${ScriptsDir}
  git fetch --all
  ExitStatusScripts=$?
  git reset --hard origin/master
  echo
}

## 更新docker-entrypoint
function Update_Entrypoint {
  if [[ ${JD_DIR} ]] && [[ $(cat ${ShellDir}/docker/docker-entrypoint.sh) != $(cat /usr/local/bin/docker-entrypoint.sh) ]]; then
    cp -f ${ShellDir}/docker/docker-entrypoint.sh /usr/local/bin/docker-entrypoint.sh
    chmod 777 /usr/local/bin/docker-entrypoint.sh
  fi
}

## 用户数量UserSum
function Count_UserSum {
  i=1
  while [ $i -le 1000 ]; do
    Tmp=Cookie$i
    CookieTmp=${!Tmp}
    [[ ${CookieTmp} ]] && UserSum=$i || break
    let i++
  done
}

## 把config.sh中提供的所有账户的PIN附加在jd_joy_run.js中，让各账户相互进行宠汪汪赛跑助力
function Change_JoyRunPins {
  j=${UserSum}
  PinALL=""
  while [[ $j -ge 1 ]]
  do
    Tmp=Cookie$j
    CookieTemp=${!Tmp}
    PinTemp=$(echo ${CookieTemp} | perl -pe "{s|.*pt_pin=(.+);|\1|; s|%|\\\x|g}")
    PinTempFormat=$(printf ${PinTemp})
    PinALL="${PinTempFormat},${PinALL}"
    let j--
  done
  perl -i -pe "{s|(let invite_pins = \[\')(.+\'\];?)|\1${PinALL}\2|; s|(let run_pins = \[\')(.+\'\];?)|\1${PinALL}\2|}" ${ScriptsDir}/jd_joy_run.js
}

## 修改lxk0301大佬js文件的函数汇总
function Change_ALL {
  if [ -f ${FileConf} ]; then
    . ${FileConf}
    if [ -n "${Cookie1}" ]; then
      Count_UserSum
      # Change_JoyRunPins
    fi
  fi
}

## 检测文件：LXK9301/jd_scripts 仓库中的 docker/crontab_list.sh
## 检测定时任务是否有变化，此函数会在Log文件夹下生成四个文件，分别为：
## task.list    crontab.list中的所有任务清单，仅保留脚本名
## js.list      上述检测文件中用来运行js脚本的清单（去掉后缀.js，非运行脚本的不会包括在内）
## js-add.list  如果上述检测文件增加了定时任务，这个文件内容将不为空
## js-drop.list 如果上述检测文件删除了定时任务，这个文件内容将不为空
function Diff_Cron {
  if [ -f ${ListCron} ]; then
    if [ -n "${JD_DIR}" ]
    then
      grep -E " j[drx]_\w+" ${ListCron} | perl -pe "s|.+ (j[drx]_\w+).*|\1|" | sort -u > ${ListTask}
    else
      grep "${ShellDir}/" ${ListCron} | grep -E " j[drx]_\w+" | perl -pe "s|.+ (j[drx]_\w+).*|\1|" | sort -u > ${ListTask}
    fi
    cat ${ListCronLxk} | grep -E "j[drx]_\w+\.js" | perl -pe "s|.+(j[drx]_\w+)\.js.+|\1|" | sort -u > ${ListJs}
    if [[ ${EnableExtraShell} == true ]]; then
      ls ${ShellDir}/diy/ | grep .js | cut -d "." -f 1 | sort -u >> ${ListJs} && ls ${ShellDir}/diy/ | grep .js | cut -d "." -f 1 | sort -u >> ${ListTask}
    fi
    grep -vwf ${ListTask} ${ListJs} > ${ListJsAdd}
    grep -vwf ${ListJs} ${ListTask} > ${ListJsDrop}
  else
    echo -e "${ListCron} 文件不存在，请先定义你自己的crontab.list...\n"
  fi
}

## 发送删除失效定时任务的消息
function Notify_DropTask {
  cd ${ShellDir}
  node update.js
  [ -f ${ContentDropTask} ] && rm -f ${ContentDropTask}
}

## 发送新的定时任务消息
function Notify_NewTask {
  cd ${ShellDir}
  node update.js
  [ -f ${ContentNewTask} ] && rm -f ${ContentNewTask}
}

## 检测配置文件版本
function Notify_Version {
  ## 识别出两个文件的版本号
  VerConfSample=$(grep " Version: " ${FileConfSample} | perl -pe "s|.+v((\d+\.?){3})|\1|")
  [ -f ${FileConf} ] && VerConf=$(grep " Version: " ${FileConf} | perl -pe "s|.+v((\d+\.?){3})|\1|")
  
  ## 删除旧的发送记录文件
  [ -f "${SendCount}" ] && [[ $(cat ${SendCount}) != ${VerConfSample} ]] && rm -f ${SendCount}

  ## 识别出更新日期和更新内容
  UpdateDate=$(grep " Date: " ${FileConfSample} | awk -F ": " '{print $2}')
  UpdateContent=$(grep " Update Content: " ${FileConfSample} | awk -F ": " '{print $2}')

  ## 如果是今天，并且版本号不一致，则发送通知
  if [ -f ${FileConf} ] && [[ "${VerConf}" != "${VerConfSample}" ]] && [[ ${UpdateDate} == $(date "+%Y-%m-%d") ]]
  then
    if [ ! -f ${SendCount} ]; then
      echo -e "检测到配置文件config.sh.sample有更新\n\n更新日期: ${UpdateDate}\n当前版本: ${VerConf}\n新的版本: ${VerConfSample}\n更新内容: ${UpdateContent}\n如需使用新功能请对照config.sh.sample，将相关新参数手动增加到你自己的config.sh中，否则请无视本消息。\n" | tee ${ContentVersion}
      echo -e "本消息只在该新版本配置文件更新当天发送一次。" >> ${ContentVersion}
      cd ${ShellDir}
      node update.js
      if [ $? -eq 0 ]; then
        echo "${VerConfSample}" > ${SendCount}
        [ -f ${ContentVersion} ] && rm -f ${ContentVersion}
      fi
    fi
  else
    [ -f ${ContentVersion} ] && rm -f ${ContentVersion}
    [ -f ${SendCount} ] && rm -f ${SendCount}
  fi
}

## npm install 子程序，判断是否为安卓，判断是否安装有yarn
function Npm_InstallSub {
  if [ -n "${isTermux}" ]
  then
    npm install --no-bin-links || npm install --no-bin-links --registry=https://registry.npm.taobao.org
  elif ! type yarn >/dev/null 2>&1
  then
    npm install || npm install --registry=https://registry.npm.taobao.org
  else
    echo -e "检测到本机安装了 yarn，使用 yarn 替代 npm...\n"
    yarn install || yarn install --registry=https://registry.npm.taobao.org
  fi
}

## npm install
function Npm_Install {
  cd ${ScriptsDir}
  if [[ "${PackageListOld}" != "$(cat package.json)" ]]; then
    echo -e "检测到package.json有变化，运行 npm install...\n"
    Npm_InstallSub
    if [ $? -ne 0 ]; then
      echo -e "\nnpm install 运行不成功，自动删除 ${ScriptsDir}/node_modules 后再次尝试一遍..."
      rm -rf ${ScriptsDir}/node_modules
    fi
    echo
  fi

  if [ ! -d ${ScriptsDir}/node_modules ]; then
    echo -e "运行 npm install...\n"
    Npm_InstallSub
    if [ $? -ne 0 ]; then
      echo -e "\nnpm install 运行不成功，自动删除 ${ScriptsDir}/node_modules...\n"
      echo -e "请进入 ${ScriptsDir} 目录后按照wiki教程手动运行 npm install...\n"
      echo -e "当 npm install 失败时，如果检测到有新任务或失效任务，只会输出日志，不会自动增加或删除定时任务...\n"
      echo -e "3...\n"
      sleep 1
      echo -e "2...\n"
      sleep 1
      echo -e "1...\n"
      sleep 1
      rm -rf ${ScriptsDir}/node_modules
    fi
  fi
}

## 输出是否有新的定时任务
function Output_ListJsAdd {
  if [ -s ${ListJsAdd} ]; then
    echo -e "检测到有新的定时任务：\n"
    cat ${ListJsAdd}
    echo
  fi
}

## 输出是否有失效的定时任务
function Output_ListJsDrop {
  if [ ${ExitStatusScripts} -eq 0 ] && [ -s ${ListJsDrop} ]; then
    echo -e "检测到有失效的定时任务：\n"
    cat ${ListJsDrop}
    echo
  fi
}

## 自动删除失效的脚本与定时任务，需要5个条件：1.AutoDelCron 设置为 true；2.正常更新js脚本，没有报错；3.js-drop.list不为空；4.crontab.list存在并且不为空；5.已经正常运行过npm install
## 检测文件：LXK9301/jd_scripts 仓库中的 docker/crontab_list.sh
## 如果检测到某个定时任务在上述检测文件中已删除，那么在本地也删除对应定时任务
function Del_Cron {
  if [ "${AutoDelCron}" = "true" ] && [ -s ${ListJsDrop} ] && [ -s ${ListCron} ] && [ -d ${ScriptsDir}/node_modules ]; then
    echo -e "开始尝试自动删除定时任务如下：\n"
    cat ${ListJsDrop}
    echo
    JsDrop=$(cat ${ListJsDrop})
    for Cron in ${JsDrop}
    do
      perl -i -ne "{print unless / ${Cron}( |$)/}" ${ListCron}
    done
    crontab ${ListCron}
    echo -e "成功删除失效的脚本与定时任务，当前的定时任务清单如下：\n\n--------------------------------------------------------------\n"
    crontab -l
    echo -e "\n--------------------------------------------------------------\n"
    if [ -d ${ScriptsDir}/node_modules ]; then
      echo -e "删除失效的定时任务：\n\n${JsDrop}" > ${ContentDropTask}
      Notify_DropTask
    fi
  fi
}

## 自动增加新的定时任务，需要5个条件：1.AutoAddCron 设置为 true；2.正常更新js脚本，没有报错；3.js-add.list不为空；4.crontab.list存在并且不为空；5.已经正常运行过npm install
## 检测文件：LXK9301/jd_scripts 仓库中的 docker/crontab_list.sh
## 如果检测到检测文件中增加新的定时任务，那么在本地也增加
## 本功能生效时，会自动从检测文件新增加的任务中读取时间，该时间为北京时间
function Add_Cron {
  if [ "${AutoAddCron}" = "true" ] && [ -s ${ListJsAdd} ] && [ -s ${ListCron} ] && [ -d ${ScriptsDir}/node_modules ]; then
    echo -e "开始尝试自动添加定时任务如下：\n"
    cat ${ListJsAdd}
    echo
    JsAdd=$(cat ${ListJsAdd})

    for Cron in ${JsAdd}
    do
      if [[ ${Cron} == jd_bean_sign ]]
      then
        echo "4 0,9 * * * bash ${ShellJd} ${Cron}" >> ${ListCron}
      else
        cat ${ListCronLxk} | grep -E "\/${Cron}\." | perl -pe "s|(^.+)node */scripts/(j[drx]_\w+)\.js.+|\1bash ${ShellJd} \2|" >> ${ListCron}
      fi
    done

    if [ $? -eq 0 ]
    then
      crontab ${ListCron}
      echo -e "成功添加新的定时任务，当前的定时任务清单如下：\n\n--------------------------------------------------------------\n"
      crontab -l
      echo -e "\n--------------------------------------------------------------\n"
      if [ -d ${ScriptsDir}/node_modules ]; then
        echo -e "成功添加新的定时任务：\n\n${JsAdd}" > ${ContentNewTask}
        Notify_NewTask
      fi
    else
      echo -e "添加新的定时任务出错，请手动添加...\n"
      if [ -d ${ScriptsDir}/node_modules ]; then
        echo -e "尝试自动添加以下新的定时任务出错，请手动添加：\n\n${JsAdd}" > ${ContentNewTask}
        Notify_NewTask
      fi
    fi
  fi
}

## 在日志中记录时间与路径
echo -e "\n--------------------------------------------------------------\n"
echo -n "系统时间："
echo $(date "+%Y-%m-%d %H:%M:%S")
if [ "${TZ}" = "UTC" ]; then
  echo
  echo -n "北京时间："
  echo $(date -d "8 hour" "+%Y-%m-%d %H:%M:%S")
fi
echo -e "\nJS脚本目录：${ScriptsDir}\n"
echo -e "--------------------------------------------------------------\n"

## 更新shell，更新docker-entrypoint, crontab
Git_PullShell
Update_Entrypoint
[[ ${ExitStatusShell} -eq 0 ]] && echo -e "更新shell成功...\n" || echo -e "更新shell失败，请检查原因...\n"
cp -f ${FileConfSample} ${ConfigDir}/config.sh.sample
[[ $(date "+%-H") -le 2 ]] && Update_Cron

## 克隆或更新js脚本
[ -f ${ScriptsDir}/package.json ] && PackageListOld=$(cat ${ScriptsDir}/package.json)
[ -d ${ScriptsDir}/.git ] && Git_PullScripts || Git_CloneScripts

## 执行各函数
if [[ ${ExitStatusScripts} -eq 0 ]]
then
  echo -e "更新scripts成功...\n"
  Change_ALL
  [ -d ${ScriptsDir}/node_modules ] && Notify_Version
  Diff_Cron
  Npm_Install
  Output_ListJsAdd
  Output_ListJsDrop
  Del_Cron
  Add_Cron
else
  echo -e "更新scripts失败，请检查原因...\n"
  Change_ALL
fi

## 调用用户自定义的diy.sh
if [[ ${EnableExtraShell} == true ]]; then
  if [ -f ${FileDiy} ]
  then
    . ${FileDiy}
  else
    echo -e "${FileDiy} 文件不存在，跳过执行DIY脚本...\n"
  fi
fi
