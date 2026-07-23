import type { Metadata } from "next";
import "./globals.css";

export const metadata: Metadata = {
  title: "昇腾算子远程实训平台",
  description: "受控 CPU 与昇腾 NPU 工作区门户",
};

export default function RootLayout({
  children,
}: Readonly<{
  children: React.ReactNode;
}>) {
  return (
    <html lang="zh-CN">
      <body>{children}</body>
    </html>
  );
}
