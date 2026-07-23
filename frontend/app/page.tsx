export default function Home() {
  return (
    <main className="grid min-h-screen place-items-center bg-background px-6 text-foreground">
      <section className="max-w-xl space-y-3 text-center">
        <p className="text-sm font-medium tracking-wide text-slate-500">
          GPC Container
        </p>
        <h1 className="text-3xl font-semibold tracking-tight">
          昇腾算子远程实训平台
        </h1>
        <p className="text-slate-600 dark:text-slate-300">
          前端基础设施已就绪；后续页面仅通过 BFF 调用受控控制面。
        </p>
      </section>
    </main>
  );
}
