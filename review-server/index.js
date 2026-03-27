const express = require("express");
const cors = require("cors");

const app = express();
app.use(cors());
app.use(express.json({ limit: "1mb" }));

const PORT = process.env.PORT || 8787;
const BASE_SUB_URL = "https://review.mock/sub/demo.json";

const nowISO = () => new Date().toISOString();

let state = {
  datas: {
    demo_bool: true,
    demo_text: "hello reviewer",
    demo_select: "on",
    demo_multi: "a,b",
  },
  sessions: [
    {
      id: "session-demo-1",
      name: "会话 1",
      enable: true,
      appId: "demo.app.settings",
      appName: "Demo Settings App",
      createTime: nowISO(),
      datas: [
        { key: "demo_bool", val: true },
        { key: "demo_text", val: "hello reviewer" },
      ],
    },
  ],
  globalbaks: [
    {
      id: "bak-1",
      name: "审核默认备份",
      createTime: nowISO(),
      tags: ["review"],
      bak: { demo: true },
    },
  ],
  curSessions: {
    "demo.app.settings": "session-demo-1",
  },
  usercfgs: {
    appsubs: [{ enable: true, id: "demo-sub-1", url: BASE_SUB_URL }],
    favapps: ["demo.app.settings"],
    bgimgs: "",
    bgimg: "",
    name: "TF Reviewer",
    icon: "",
    viewkeys: [],
    gist_cache_key: [],
    theme: "light",
    isTransparentIcons: false,
    isWallpaperMode: false,
    isMute: false,
    isMuteQueryAlert: false,
    isHideHelp: false,
    isHideBoxIcon: false,
    isHideMyTitle: false,
    isHideCoding: false,
    isHideRefresh: false,
    isDebugWeb: false,
    lang: "zh-CN",
    httpapi: "",
    httpapis: "",
  },
};

const sysapps = [
  {
    id: "demo.app.settings",
    name: "Demo Settings App",
    author: "@NEBox",
    repo: "https://example.com/review",
    descs: ["用于 TestFlight 审核的模拟应用配置"],
    keys: ["demo_bool", "demo_text", "demo_select", "demo_multi"],
    icons: [
      "https://raw.githubusercontent.com/Orz-3/mini/master/Alpha/appstore.png",
      "https://raw.githubusercontent.com/Orz-3/mini/master/Color/appstore.png",
    ],
    desc: "可在详情页修改设置、运行脚本、查看会话。",
    script: "https://example.com/script/review-run.js",
    scripts: [
      {
        name: "审核演示脚本",
        script: "https://example.com/script/review-run.js",
      },
    ],
    desc_html: "",
    descs_html: [],
    settings: [
      {
        id: "demo_bool",
        name: "演示开关",
        val: true,
        desc: "用于验证布尔设置保存",
        placeholder: "",
        type: "boolean",
        items: null,
      },
      {
        id: "demo_text",
        name: "演示文本",
        val: "hello reviewer",
        desc: "用于验证文本输入保存",
        placeholder: "请输入内容",
        type: "text",
        items: null,
      },
      {
        id: "demo_select",
        name: "演示单选",
        val: "on",
        desc: "用于验证 radios 渲染",
        placeholder: "",
        type: "radios",
        items: [
          { key: "on", label: "开启" },
          { key: "off", label: "关闭" },
        ],
      },
      {
        id: "demo_multi",
        name: "演示多选",
        val: "a,b",
        desc: "用于验证 checkboxes 渲染",
        placeholder: "",
        type: "checkboxes",
        items: [
          { key: "a", label: "选项 A" },
          { key: "b", label: "选项 B" },
          { key: "c", label: "选项 C" },
        ],
      },
    ],
  },
  {
    id: "demo.app.viewer",
    name: "Demo Viewer",
    author: "@NEBox",
    repo: "https://example.com/review",
    descs: ["用于展示列表和图标渲染"],
    keys: ["viewer_key"],
    icons: [
      "https://raw.githubusercontent.com/Orz-3/mini/master/Alpha/appstore.png",
      "https://raw.githubusercontent.com/Orz-3/mini/master/Color/appstore.png",
    ],
    desc: "演示应用",
    script: null,
    scripts: [],
    desc_html: "",
    descs_html: [],
    settings: [
      {
        id: "viewer_key",
        name: "查看模式",
        val: "simple",
        desc: "演示设置项",
        placeholder: "",
        type: "text",
        items: null,
      },
    ],
  },
];

function boxDataResp() {
  return {
    code: 0,
    message: "ok",
    appSubCaches: {
      [BASE_SUB_URL]: {
        id: "demo-sub-1",
        name: "NEBox Review Feed",
        icon: "",
        author: "@NEBox",
        repo: "https://example.com/review",
        updateTime: nowISO(),
        apps: sysapps,
        isErr: false,
        enable: true,
        url: BASE_SUB_URL,
        raw: {
          enable: true,
          id: "demo-sub-1",
          url: BASE_SUB_URL,
        },
      },
    },
    datas: state.datas,
    sessions: state.sessions,
    usercfgs: state.usercfgs,
    sysapps,
    globalbaks: state.globalbaks,
    curSessions: state.curSessions,
    syscfgs: {
      version: "0.0.5",
      env: "Loon",
      envs: [{ id: "Loon", icons: [] }],
      versionType: "review",
    },
  };
}

function ok(extra = {}) {
  return { code: 0, message: "ok", ...extra };
}

app.get("/", (_req, res) => {
  res.json({
    name: "NEBox Review Mock API",
    status: "ok",
    endpoints: ["/query/boxdata", "/query/versions", "/api/runScript"],
  });
});

app.get("/healthz", (_req, res) => {
  res.json({ ok: true, ts: nowISO() });
});

app.get("/query/boxdata", (_req, res) => {
  res.json(boxDataResp());
});

app.get("/query/versions", (_req, res) => {
  res.json(
    ok({
      releases: [
        {
          version: "0.0.5",
          notes: [
            { name: "TestFlight 审核版本", descs: ["这是审核专用模拟服务。"] },
          ],
        },
      ],
    })
  );
});

app.get("/query/data/:key", (req, res) => {
  const key = req.params.key;
  const value = Object.prototype.hasOwnProperty.call(state.datas, key)
    ? state.datas[key]
    : "";
  res.json(ok({ val: value }));
});

app.get("/query/baks/:id", (req, res) => {
  const bak = state.globalbaks.find((b) => b.id === req.params.id);
  res.json(ok({ ...(bak?.bak || {}) }));
});

app.post("/api/update", (req, res) => {
  const { path, val } = req.body || {};
  if (typeof path === "string") {
    if (path.startsWith("usercfgs.")) {
      const key = path.slice("usercfgs.".length);
      state.usercfgs[key] = val;
    } else {
      state.datas[path] = val;
    }
  }
  res.json(boxDataResp());
});

app.post("/api/save", (req, res) => {
  const payload = req.body;
  if (Array.isArray(payload)) {
    for (const item of payload) {
      if (item && typeof item.key === "string") {
        state.datas[item.key] = item.val ?? "";
      }
    }
  }
  res.json(boxDataResp());
});

app.post("/api/saveData", (req, res) => {
  const { key, val } = req.body || {};
  if (typeof key === "string") {
    state.datas[key] = val ?? "";
  }
  res.json(boxDataResp());
});

app.post("/api/runScript", (req, res) => {
  const { url, script } = req.body || {};
  const trigger = String(url || script || "");
  const hasError = trigger.toLowerCase().includes("error") || trigger.toLowerCase().includes("throw");
  if (hasError) {
    return res.json(ok({ exception: "Demo error: simulated script failure", output: "" }));
  }
  return res.json(
    ok({
      exception: "",
      output: `Demo run succeeded at ${nowISO()}\nsource=${trigger || "inline"}`,
    })
  );
});

app.post("/api/reloadAppSub", (_req, res) => res.json(boxDataResp()));
app.post("/api/addAppSub", (_req, res) => res.json(boxDataResp()));
app.post("/api/deleteAppSub", (_req, res) => res.json(boxDataResp()));
app.post("/api/saveGlobalBak", (_req, res) => res.json(boxDataResp()));
app.post("/api/impGlobalBak", (_req, res) => res.json(boxDataResp()));
app.post("/api/delGlobalBak", (_req, res) => res.json(boxDataResp()));
app.post("/api/revertGlobalBak", (_req, res) => res.json(boxDataResp()));
app.post("/api/updateGlobalBak", (_req, res) => res.json(boxDataResp()));

app.use((_req, res) => {
  res.status(404).json({ code: 404, message: "not found" });
});

app.listen(PORT, () => {
  console.log(`[review-server] listening on :${PORT}`);
});

