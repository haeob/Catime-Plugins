@echo off
:: 强制 CMD 窗口使用 UTF-8 编码
chcp 65001 >nul
setlocal EnableDelayedExpansion
cd /d "%~dp0"
title Gold Price Monitor

:: --- 配置区域 ---
set API_URL=https://papi.icbc.com.cn/wapDynamicPage/goldMarket/accList
set OUTPUT_FILE=output.txt
set REQUEST_INTERVAL_SEC=10
set REQUEST_TIMEOUT_SEC=10

:LOOP
cls
for /f "usebackq delims=" %%T in (`
    powershell -NoProfile -Command ^
      "[Console]::OutputEncoding = [System.Text.Encoding]::UTF8;" ^
      "$ErrorActionPreference='Stop'; $ProgressPreference='SilentlyContinue';" ^
      "$url='%API_URL%'; $outFile='%OUTPUT_FILE%';" ^
      "try {" ^
      "  $resp = Invoke-RestMethod -Uri $url -TimeoutSec %REQUEST_TIMEOUT_SEC%;" ^
      "  if (-not $resp -or $resp.code -ne 0) { throw 'BadResponse' };" ^
      "  $gold = $resp.data | Where-Object { $_.id -eq '901001' } | Select-Object -First 1;" ^
      "  if (-not $gold) { throw 'NoData' };" ^
      "  $price = $gold.zjj;" ^
      "  $rateStr = $gold.upDownRate;" ^
      "  $rateDouble = [double]$rateStr;" ^
      "  $sign = if ($rateDouble -gt 0) { '+' } else { '' };" ^
      "  $text = '当前金价' + $price + '元/g，涨跌幅' + $sign + $rateStr + [char]37;" ^
      "  $text | Out-File -FilePath $outFile -Encoding UTF8;" ^
      "  Write-Output $text;" ^
      "} catch {" ^
      "  $fallback = '当前金价获取失败，等待重试...';" ^
      "  $fallback | Out-File -FilePath $outFile -Encoding UTF8;" ^
      "  Write-Output $fallback;" ^
      "}"
`) do echo %%T

timeout /t %REQUEST_INTERVAL_SEC% >nul
goto LOOP