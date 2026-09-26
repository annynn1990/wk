const crypto = require('crypto');

const enc = s => Buffer.from(s).toString('base64url');
const sign = value => crypto.createHmac('sha256', process.env.WIKI_AUTH_SECRET || '').update(value).digest('base64url');

module.exports = async (req, res) => {
  res.setHeader('Cache-Control', 'no-store');
  if (req.method !== 'POST') return res.status(405).json({ok:false,error:'Method not allowed'});
  const {password} = req.body || {};
  if (!process.env.WIKI_EDIT_PASSWORD || !process.env.WIKI_AUTH_SECRET) {
    return res.status(500).json({ok:false,error:'Editor authentication is not configured'});
  }
  if (typeof password !== 'string' || !crypto.timingSafeEqual(
    Buffer.from(password),
    Buffer.from(process.env.WIKI_EDIT_PASSWORD)
  )) {
    return res.status(401).json({ok:false,error:'密碼錯誤'});
  }
  const payload = enc(JSON.stringify({exp: Date.now() + 8 * 60 * 60 * 1000}));
  return res.status(200).json({ok:true,token:payload+'.'+sign(payload)});
};
