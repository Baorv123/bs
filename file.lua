// ==UserScript==
// @name         UGPHONE VIP TOOL (By Gia Bảo)
// @namespace    https://ugphone.com/
// @version      1.0
// @description  Auto mua máy UGPhone 4H theo server chọn (HongKong/Singapore)
// @author       Gia Bảo
// @match        https://www.ugphone.com/toc-portal/#/login
// @match        https://www.ugphone.com/toc-portal/#/dashboard/index
// @icon         https://cdn-icons-png.flaticon.com/512/1995/1995485.png
// @grant        none
// ==/UserScript==

(function() {
  'use strict';

  const STYLE = `
    #ug-floating-btn {
      position: fixed;
      top: 100px;
      right: 20px;
      z-index: 9999;
      background: #4a6bdf;
      color: white;
      padding: 12px 16px;
      border-radius: 10px;
      cursor: pointer;
      box-shadow: 0 4px 12px rgba(0,0,0,0.2);
      font-weight: bold;
    }
    #ug-panel {
      position: fixed;
      top: 160px;
      right: 20px;
      width: 300px;
      background: white;
      border: 2px solid #4a6bdf;
      border-radius: 10px;
      padding: 16px;
      box-shadow: 0 4px 12px rgba(0,0,0,0.2);
      z-index: 9999;
      display: none;
      font-family: Arial, sans-serif;
    }
    #ug-panel select, #ug-panel button {
      width: 100%;
      margin-top: 10px;
      padding: 10px;
      border-radius: 6px;
      border: 1px solid #ccc;
    }
  `;

  const style = document.createElement('style');
  style.innerHTML = STYLE;
  document.head.appendChild(style);

  const btn = document.createElement('div');
  btn.id = 'ug-floating-btn';
  btn.textContent = 'Auto UGPhone';
  document.body.appendChild(btn);

  const panel = document.createElement('div');
  panel.id = 'ug-panel';
  panel.innerHTML = `
    <b>UGPHONE Tool by Gia Bảo</b>
    <select id="ug-server">
      <option value="HongKong">HongKong</option>
      <option value="Singapore">Singapore</option>
    </select>
    <button id="ug-buy">Mua Máy UGPhone 4H</button>
  `;
  document.body.appendChild(panel);

  btn.onclick = () => {
    panel.style.display = panel.style.display === 'none' ? 'block' : 'none';
  };

  document.getElementById('ug-buy').onclick = async () => {
    try {
      const mqtt = JSON.parse(localStorage.getItem('UGPHONE-MQTT') || '{}');
      const headers = {
        'accept': 'application/json, text/plain, */*',
        'accept-language': 'vi-VN',
        'content-type': 'application/json;charset=UTF-8',
        'lang': 'vi',
        'terminal': 'web',
        'access-token': mqtt.access_token,
        'login-id': mqtt.login_id
      };

      const configRes = await fetch('https://www.ugphone.com/api/apiv1/info/configList2', { headers });
      const configJson = await configRes.json();
      const config_id = configJson.data?.list?.[0]?.android_version?.[0]?.config_id;
      if (!config_id) return alert('Lỗi lấy config_id');

      const mealRes = await fetch('https://www.ugphone.com/api/apiv1/info/mealList', {
        method: 'POST',
        headers,
        body: JSON.stringify({ config_id })
      });
      const mealJson = await mealRes.json();
      const serverName = document.getElementById('ug-server').value;

      let subscriptions = [];
      let subData = mealJson.data?.list;
      if (Array.isArray(subData)) subscriptions = subData.flatMap(i => i.subscription || []);

      const filtered = subscriptions.filter(s => s.network_name?.includes(serverName));

      for (const s of filtered) {
        const priceRes = await fetch('https://www.ugphone.com/api/apiv1/fee/queryResourcePrice', {
          method: 'POST',
          headers,
          body: JSON.stringify({
            order_type: 'newpay',
            period_time: '4',
            unit: 'hour',
            resource_type: 'cloudphone',
            resource_param: {
              pay_mode: 'subscription',
              config_id,
              network_id: s.network_id,
              count: 1,
              use_points: 3,
              points: 250
            }
          })
        });
        const priceJson = await priceRes.json();
        const amount_id = priceJson.data?.amount_id;
        if (!amount_id) continue;

        const payRes = await fetch('https://www.ugphone.com/api/apiv1/fee/payment', {
          method: 'POST',
          headers,
          body: JSON.stringify({ amount_id, pay_channel: 'free' })
        });
        const payJson = await payRes.json();

        if (payJson.code === 200) {
          alert('✅ Mua máy thành công!');
          location.reload();
          return;
        }
      }
      alert('❌ Hết máy hoặc sai sever!');
    } catch (err) {
      console.error(err);
      alert('❌ Lỗi khi mua máy');
    }
  };
})();
