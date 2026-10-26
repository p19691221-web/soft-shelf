// 小禾陪你聊 · Supabase Edge Function（名稱：xiaohe）
// 網頁把對話送來，這裡用你的 Claude API 金鑰請小禾回話。金鑰只存在 Supabase 的 Secrets，不會出現在網頁上。
// 需要的 Secret：ANTHROPIC_API_KEY

const MODEL = "claude-haiku-5-5";
const PER_HOUR = 60;      // 同一個來源每小時最多幾句
const PER_DAY = 3000;     // 全部人加起來每天最多幾句

const CORS = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers": "authorization, apikey, content-type, x-client-info",
  "Access-Control-Allow-Methods": "POST, OPTIONS",
};
const json = (body: unknown, status = 200) =>
  new Response(JSON.stringify(body), { status, headers: { ...CORS, "Content-Type": "application/json" } });

const RULES = `你是「小禾」，一位用聲音陪人聊天的朋友。你說的每句話都會被手機念出來，對方是用語音跟你說話。

說話方式：
- 用台灣口語的繁體中文，像朋友講電話一樣自然。
- 每次只說 1 到 3 句短句，總共不超過 60 個字。
- 不要用條列、編號、標題、表情符號、括號、網址或任何 Markdown，念出來會很怪。
- 多聽少說：接住對方的話，偶爾問一個簡單的問題讓對話繼續，但不要每句都問。
- 語音辨識常有錯字或同音字，請猜對方真正的意思，不要糾正錯字。
- 對方說英文或台語，就跟著用對方的語言回。

界線：
- 你是 AI，不要假裝是人；被問到就直說。
- 你只陪人聊天。被要求寫程式、寫長文章、翻譯長篇內容或做作業時，簡短婉拒，把話題帶回聊天。
- 不給醫療、法律、投資的具體建議，溫和地建議找專業的人。
- 如果對方提到想傷害自己或很危險的狀況，先關心他，告訴他可以打 1925 安心專線（24 小時），緊急時打 119。`;

function groupRules(people: string[]) {
  if (people.length < 2) return "";
  return `\n\n現在是 ${people.length} 個人圍著同一支手機輪流跟你聊天：${people.join("、")}。每則訊息開頭的【名字】代表是誰說的。回話時自然地叫對方的名字，記得每個人說過什麼；如果有人一直沒開口，偶爾點名邀他說說看，但不要每次都點名。`;
}

// 整理網頁送來的對話：只留最近 20 則、每則最多 500 字、由使用者開頭和結尾、同一方連續的合併
function cleanTurns(raw: unknown) {
  const list = Array.isArray(raw) ? raw : [];
  const out: { role: "user" | "assistant"; content: string }[] = [];
  for (const t of list.slice(-20)) {
    const role = t && (t as any).role === "assistant" ? "assistant" : "user";
    const content = String((t && (t as any).content) || "").trim().slice(0, 500);
    if (!content) continue;
    const last = out[out.length - 1];
    if (last && last.role === role) last.content += "\n" + content;
    else out.push({ role, content });
  }
  while (out.length && out[0].role !== "user") out.shift();
  while (out.length && out[out.length - 1].role !== "user") out.pop();
  return out;
}

async function take(who: string) {
  const url = Deno.env.get("SUPABASE_URL");
  const key = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY");
  if (!url || !key) return true;   // 沒有資料庫設定時不擋（正常部署一定會有）
  const r = await fetch(url + "/rest/v1/rpc/xh_take", {
    method: "POST",
    headers: { apikey: key, Authorization: "Bearer " + key, "Content-Type": "application/json" },
    body: JSON.stringify({ p_who: who, p_hour: PER_HOUR, p_day: PER_DAY }),
  });
  if (!r.ok) return true;          // 計數失敗時不擋，避免整個停擺；金鑰端仍有你設定的花費上限
  return (await r.json()) === true;
}

Deno.serve(async (req: Request) => {
  if (req.method === "OPTIONS") return new Response("ok", { headers: CORS });
  if (req.method !== "POST") return json({ error: "只接受 POST" }, 405);

  const apiKey = Deno.env.get("ANTHROPIC_API_KEY");
  if (!apiKey) return json({ error: "還沒設定 ANTHROPIC_API_KEY" }, 500);

  let body: any;
  try { body = await req.json(); } catch { return json({ error: "格式不對" }, 400); }
  const turns = cleanTurns(body && body.turns);
  if (!turns.length) return json({ error: "沒有收到要說的話" }, 400);
  const people = (Array.isArray(body.people) ? body.people : [])
    .map((x: unknown) => String(x).replace(/[【】\n]/g, "").trim().slice(0, 8)).filter(Boolean).slice(0, 8);

  const who = (req.headers.get("x-forwarded-for") || "").split(",")[0].trim() || "unknown";
  if (!(await take(who))) return json({ error: "busy", message: "今天小禾聊太多了，休息一下再來。" }, 429);

  const r = await fetch("https://api.anthropic.com/v1/messages", {
    method: "POST",
    headers: { "x-api-key": apiKey, "anthropic-version": "2023-06-01", "content-type": "application/json" },
    body: JSON.stringify({ model: MODEL, max_tokens: 300, system: RULES + groupRules(people), messages: turns }),
  });
  const j = await r.json().catch(() => null);
  if (!r.ok) {
    const msg = j && j.error && j.error.message || ("HTTP " + r.status);
    console.error("anthropic", r.status, msg);
    return json({ error: "upstream", message: r.status === 429 || r.status === 529 ? "小禾那邊有點塞，等一下再說。" : "小禾一時接不上話，再說一次看看。" }, 502);
  }
  const text = (j.content || []).filter((c: any) => c.type === "text").map((c: any) => c.text).join("").trim();
  return json({ text: text || "嗯，我在聽。" });
});
