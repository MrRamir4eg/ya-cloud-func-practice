import json

FUNC_RESPONSE = {
    'statusCode': 200,
    'body': ''
}

def get_ip(event):
    if event['headers'].get('X-Forwarded-For') != None:
        return event['headers']['X-Forwarded-For'].split(',')[0]
    else:
        return event['requestContext']['identity']['sourceIp']


def handler(event, context):
    url_path = event.get('path')
    ip_addr = get_ip(event)

    if 'curl' in event['headers']['User-Agent'] and (url_path in ('/', '/json')):
        if url_path == '/':
            FUNC_RESPONSE['body'] = f"{ip_addr}"
            FUNC_RESPONSE['headers'] = {'Content-Type': 'text/plain'}
        elif url_path == '/json':
            FUNC_RESPONSE['body'] = json.dumps({
                "ip": f"{ip_addr}"
            })
            FUNC_RESPONSE['headers'] = {'Content-Type': 'application/json'}
    else:
        FUNC_RESPONSE['body'] = f"<p>{ip_addr}</p>"
        FUNC_RESPONSE['headers'] = {'Content-Type': 'text/html'}

    return FUNC_RESPONSE
