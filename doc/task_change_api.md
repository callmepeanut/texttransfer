# 任务
修改目前的 api

## 新 API 信息

### 创建 & 更新
key：6位及以上，60位及以下字符，不支持斜线/
curl 示例：
curl --request POST \
  --url 'https://api.textdb.online/update/?key=131690600e2b79b47109' \
  --header 'content-type: multipart/form-data' \
  --form 'value={"name":"dhafksdhfjasdl;j"}'

### 获取
curl 示例：
curl --request GET \
  --url https://textdb.online/131690600e2b79b47109

响应内容为：{"name":"dhafksdhfjasdl;j"}
content-type为text/plain


## 要求
html 的“一键生成配置”，从生成笔记本名称和密码改为只生成 key，长度为 42 位随机字符串（不支持斜线/）
对应的 flutter 的扫码获取配置逻辑也需要同步修改
base64 编码保留
