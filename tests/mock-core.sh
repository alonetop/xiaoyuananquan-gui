#!/bin/sh
printf '请输入学校所在省份[回车默认江苏省]：'
IFS= read -r province
printf '收到省份：%s\n' "$province"
printf '请输入学校名称[关键词也可以]：'
IFS= read -r school
printf '[1] 测试第一学校\n[2] 测试第二学校\n请输入学校序号：'
IFS= read -r choice
printf '已选择：%s\n' "$choice"
printf '请输入账号：'
IFS= read -r account
printf '收到账号：%s\n' "$account"
printf '请输入密码：'
IFS= read -r password
printf '模拟运行完成；密码长度：%s\n' "${#password}"
