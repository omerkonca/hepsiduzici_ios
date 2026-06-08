/**
 * Hepsi Düziçi backend — push bildirim route'ları dahil minimal sunucu.
 * Mevcut Render deploy'unuza `push` router'ını eklemeniz yeterli.
 */
import cors from 'cors';
import express from 'express';
import pushRouter from './routes/push.js';

const app = express();
const port = process.env.PORT || 5050;

app.use(cors());
app.use(express.json({ limit: '2mb' }));

app.get('/health', (_req, res) => {
  res.json({ ok: true, service: 'hepsiduzici-backend' });
});

app.get('/api/admin/check', (req, res) => {
  const token = req.headers['x-admin-token'];
  const expected = process.env.ADMIN_TOKEN;
  if (expected && token === expected) {
    return res.json({ ok: true });
  }
  return res.status(401).json({ ok: false });
});

app.use('/api/push', pushRouter);

app.listen(port, () => {
  console.log(`Backend listening on ${port}`);
});
