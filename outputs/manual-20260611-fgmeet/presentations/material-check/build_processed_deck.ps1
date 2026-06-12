param(
    [string]$OutputDir = "G:\fg-meet-workbench\outputs\manual-20260611-fgmeet\presentations\material-check\output"
)

$ErrorActionPreference = "Stop"

function OleColor([int]$r, [int]$g, [int]$b) {
    return [System.Drawing.ColorTranslator]::ToOle([System.Drawing.Color]::FromArgb($r, $g, $b))
}

function Add-Text($slide, [double]$x, [double]$y, [double]$w, [double]$h, [string]$text, [double]$size = 18, [bool]$bold = $false, [int]$color = $script:Ink, [string]$align = "left") {
    $shape = $slide.Shapes.AddTextbox(1, $x, $y, $w, $h)
    $shape.TextFrame.TextRange.Text = $text
    $shape.TextFrame.MarginLeft = 6
    $shape.TextFrame.MarginRight = 6
    $shape.TextFrame.MarginTop = 4
    $shape.TextFrame.MarginBottom = 4
    $shape.TextFrame.WordWrap = -1
    $font = $shape.TextFrame.TextRange.Font
    $font.Name = "Microsoft YaHei"
    $font.NameFarEast = "Microsoft YaHei"
    $font.Size = $size
    $font.Bold = $(if ($bold) { -1 } else { 0 })
    $font.Color.RGB = $color
    switch ($align) {
        "center" { $shape.TextFrame.TextRange.ParagraphFormat.Alignment = 2 }
        "right" { $shape.TextFrame.TextRange.ParagraphFormat.Alignment = 3 }
        default { $shape.TextFrame.TextRange.ParagraphFormat.Alignment = 1 }
    }
    return $shape
}

function Add-Header($slide, [string]$title, [int]$page) {
    $bar = $slide.Shapes.AddShape(1, 0, 0, 960, 42)
    $bar.Fill.ForeColor.RGB = $script:LightBlue
    $bar.Line.Visible = 0
    Add-Text $slide 24 7 760 28 $title 18 $true $script:Ink | Out-Null
    Add-Text $slide 818 7 118 26 "上海大学" 12 $true $script:BrandBlue "right" | Out-Null
    $footer = $slide.Shapes.AddShape(1, 0, 508, 960, 32)
    $footer.Fill.ForeColor.RGB = $script:BrandBlue
    $footer.Line.Visible = 0
    Add-Text $slide 720 513 210 18 "$page/9" 8 $false $script:White "right" | Out-Null
}

function Add-SectionLabel($slide, [double]$x, [double]$y, [string]$text, [int]$fillColor) {
    $box = $slide.Shapes.AddShape(1, $x, $y, 250, 34)
    $box.Fill.ForeColor.RGB = $fillColor
    $box.Line.ForeColor.RGB = $fillColor
    Add-Text $slide ($x + 8) ($y + 5) 235 22 $text 12 $true $script:White | Out-Null
}

function Add-Table($slide, [double]$x, [double]$y, [double]$w, [double]$h, [object[]]$headers, [object[]]$rows, [double]$fontSize = 10) {
    $shape = $slide.Shapes.AddTable($rows.Count + 1, $headers.Count, $x, $y, $w, $h)
    $table = $shape.Table
    for ($c = 1; $c -le $headers.Count; $c++) {
        $cell = $table.Cell(1, $c)
        $cell.Shape.Fill.ForeColor.RGB = $script:BrandBlue
        $tr = $cell.Shape.TextFrame.TextRange
        $tr.Text = [string]$headers[$c - 1]
        $tr.Font.Name = "Microsoft YaHei"
        $tr.Font.NameFarEast = "Microsoft YaHei"
        $tr.Font.Size = $fontSize
        $tr.Font.Bold = -1
        $tr.Font.Color.RGB = $script:White
    }
    for ($r = 1; $r -le $rows.Count; $r++) {
        $row = $rows[$r - 1]
        for ($c = 1; $c -le $headers.Count; $c++) {
            $cell = $table.Cell($r + 1, $c)
            $cell.Shape.Fill.ForeColor.RGB = $(if ($r % 2 -eq 0) { $script:VeryLightBlue } else { $script:White })
            $cell.Shape.TextFrame.MarginLeft = 4
            $cell.Shape.TextFrame.MarginRight = 4
            $cell.Shape.TextFrame.MarginTop = 2
            $cell.Shape.TextFrame.MarginBottom = 2
            $tr = $cell.Shape.TextFrame.TextRange
            $tr.Text = [string]$row[$c - 1]
            $tr.Font.Name = "Microsoft YaHei"
            $tr.Font.NameFarEast = "Microsoft YaHei"
            $tr.Font.Size = $fontSize
            $tr.Font.Color.RGB = $script:Ink
        }
    }
    return $shape
}

function Add-Card($slide, [double]$x, [double]$y, [double]$w, [double]$h, [string]$title, [string]$body, [int]$accent) {
    $card = $slide.Shapes.AddShape(1, $x, $y, $w, $h)
    $card.Fill.ForeColor.RGB = $script:White
    $card.Line.ForeColor.RGB = $script:Border
    $stripe = $slide.Shapes.AddShape(1, $x, $y, 7, $h)
    $stripe.Fill.ForeColor.RGB = $accent
    $stripe.Line.Visible = 0
    Add-Text $slide ($x + 16) ($y + 12) ($w - 28) 24 $title 15 $true $accent | Out-Null
    Add-Text $slide ($x + 16) ($y + 44) ($w - 28) ($h - 54) $body 11 $false $script:Ink | Out-Null
}

New-Item -ItemType Directory -Force -Path $OutputDir | Out-Null

$script:BrandBlue = OleColor 0 40 104
$script:LightBlue = OleColor 219 234 250
$script:VeryLightBlue = OleColor 242 247 253
$script:Ink = OleColor 20 32 48
$script:Muted = OleColor 102 112 128
$script:White = OleColor 255 255 255
$script:Red = OleColor 192 0 0
$script:Green = OleColor 21 128 61
$script:Amber = OleColor 180 83 9
$script:Border = OleColor 184 199 218

$pptPath = Join-Path $OutputDir "组会6.7_处理版_五点更新版.pptx"
$pdfPath = Join-Path $OutputDir "组会6.7_处理版_五点更新版.pdf"

$app = New-Object -ComObject PowerPoint.Application
$app.Visible = -1
$pres = $app.Presentations.Add()
$pres.PageSetup.SlideWidth = 960
$pres.PageSetup.SlideHeight = 540

# Slide 1
$slide = $pres.Slides.Add(1, 12)
Add-Text $slide 34 22 170 34 "上海大学" 16 $true $script:BrandBlue | Out-Null
$box = $slide.Shapes.AddShape(1, 50, 132, 860, 112)
$box.Fill.ForeColor.RGB = $script:BrandBlue
$box.Line.Visible = 0
Add-Text $slide 50 156 860 42 "组会汇报" 27 $true (OleColor 255 255 0) "center" | Out-Null
Add-Text $slide 50 207 860 30 "五点验证更新版" 16 $true $script:White "center" | Out-Null
Add-Text $slide 50 276 860 34 "尤慧雯" 18 $true $script:Ink "center" | Out-Null
Add-Text $slide 50 318 860 28 "2026年6月12日" 12 $true $script:Ink "center" | Out-Null

# Slide 2
$slide = $pres.Slides.Add(2, 12)
Add-Header $slide "材料核对结论" 2
Add-Card $slide 42 82 408 112 "新增材料" "钱沈云、赵亚飞论文和代码已入库；钱沈云 2026 文章含 COMSOL 与 present model 对比表。" $script:BrandBlue
Add-Card $slide 510 82 408 112 "核心更新" "第 2 点已找到直接外部对照：300 V 电压和 200 A 磁势致变形与钱沈云 Table 4/Table 5 基本一致。" $script:Green
Add-Card $slide 42 232 408 112 "仍需谨慎" "第 1 点原始 COMSOL 最大误差 4.93%，刚度敏感性后 2.72%；3% 结论还要解释物理来源。" $script:Amber
Add-Card $slide 510 232 408 112 "下一关键" "第 3 点位移回代电势/磁势还没闭环；旧 2 mm 表是过期中心位移口径，不能直接用。" $script:Red
Add-Text $slide 46 383 868 72 "处理原则：材料已经从【缺外部基准】推进到【第二点有外部表格对上】。本版把五点更新成验证矩阵，明确哪些能讲、哪些必须待复算。" 15 $true $script:Ink | Out-Null

# Slide 3
$slide = $pres.Slides.Add(3, 12)
Add-Header $slide "导师反馈拆解：三道验证关口" 3
$headers = @("关口", "要证明什么", "现有材料状态", "处理判断")
$rows = @(
    @("1 力→位移", "加力后结构变形是否算对", "MATLAB-COMSOL 15 点对照；另有钱沈云机械载荷收敛口径", "可讲可用，严格 3% 仍需物理口径解释"),
    @("2 电/磁→位移", "电压、磁势驱动变形是否算对", "钱沈云 Table 4/Table 5 可直接对照", "已基本对上，可作为完成验证项"),
    @("3 位移→电/磁", "力致位移后回代电势/磁势是否正确", "钱沈云 RWR 回代代码已定位", "未完成，下一步必须重跑闭环"),
    @("4/5 论文可用性", "结果能否作为论文证据", "验证矩阵已形成", "参数扫描先放附录，前三点按周推进")
)
Add-Table $slide 38 86 884 256 $headers $rows 10 | Out-Null
Add-SectionLabel $slide 52 382 "本周最小可交付" $script:BrandBlue
Add-Text $slide 328 378 560 54 "把第 2 点先讲稳：300 V 和 200 A 致变形已和钱沈云论文表格对上；第 1 点继续补 3% 物理口径，第 3 点作为下一步闭环。" 16 $true $script:Ink | Out-Null

# Slide 4
$slide = $pres.Slides.Add(4, 12)
Add-Header $slide "关口 1：力加载位移已有独立对照" 4
$headers = @("工况", "边界/载荷", "中心误差", "15点最大误差", "处理状态")
$rows = @(
    @("U / Vf0=0.6", "CFFF / -15000 Pa", "3.771%", "4.927%", "低于 5%，但高于导师期望"),
    @("U / Vf0=0.6", "刚度敏感性 1.0215", "1.587%", "2.718%", "进入 3%，但需解释物理来源"),
    @("V / Vf0=0.6", "CFFF / -15000 Pa", "2.959%", "4.190%", "可作为非 U 补充证据"),
    @("X / Vf0=0.6", "CFFF / -15000 Pa", "2.839%", "4.060%", "可作为非 U 补充证据"),
    @("X / Vf0=0.1", "CFCF / -15000 Pa", "3.831%", "3.831%", "精细网格后通过")
)
Add-Table $slide 36 82 888 246 $headers $rows 10.5 | Out-Null
Add-Text $slide 48 354 854 58 "结论写法：力-位移链路可用；小幅等效刚度敏感性可把 U/CFFF 最大误差压到 2.72%。但正式写进论文前，要用钱沈云机械载荷表/图或板理论解释 1.0215 的来源。" 15 $true $script:Ink | Out-Null
Add-Text $slide 48 438 854 36 "补充依据：钱沈云 2026 文章第 8-9 页，15000 Pa 均布载荷下 present 与 COMSOL 位移偏差代表值 0.76%。" 10 $false $script:Muted | Out-Null

# Slide 5
$slide = $pres.Slides.Add(5, 12)
Add-Header $slide "关口 2：电/磁驱动位移已对上外部表格" 5
$headers = @("驱动", "我们当前程序", "钱沈云 present", "钱沈云 COMSOL", "判断")
$rows = @(
    @("300 V 电压", "-0.052257 mm", "-5.23E-02 mm", "-5.23E-02 mm", "约 0.08%，对上"),
    @("200 A 磁势", "0.174586 mm", "1.75E-01 mm", "1.73E-01 mm", "约 0.24% / 0.92%，对上")
)
Add-Table $slide 50 88 860 120 $headers $rows 11 | Out-Null
Add-Card $slide 54 250 392 126 "可以直接这么讲" "电压和磁势正向致变形这一步，已经与钱沈云论文 Table 4/Table 5 的 CFFF 中点数值基本一致，可以作为已完成外部验证。" $script:Green
Add-Card $slide 516 250 392 126 "同步修正" "旧 output/coupling_validation_2mm.csv 是中心位移修正前的过期口径；2 mm 反算值应更新为约 11481.7 V 和 2291.1 A。" $script:Amber
Add-Text $slide 48 430 854 38 "证据路径：钱沈云 2026 论文 Table 4/Table 5；MEET-electro-thermal/MEET_CFFF_thermal.m；MEET-magneto-thermal/MEET_CFFF_thermal.m" 10 $false $script:Muted | Out-Null

# Slide 6
$slide = $pres.Slides.Add(6, 12)
Add-Header $slide "关口 3：位移回代电/磁势仍未闭环" 6
Add-Text $slide 52 80 856 42 "现在最关键的缺口已经收窄：不是电/磁驱动位移，而是【由力产生位移，再回代电势或磁势】。这一点没对上，后面的耦合结果仍不能写成论文结论。" 15 $true $script:Ink | Out-Null
$headers = @("需要补的基准", "已有入口", "下一步怎么处理")
$rows = @(
    @("力→位移严格 3%", "钱沈云机械载荷表/图 + 当前 COMSOL 表", "解释刚度敏感性来源，补同口径外部图表"),
    @("位移→电势", "钱沈云 RWR 代码回代 SensM_E", "用当前中心位移口径重跑，生成误差表"),
    @("位移→磁势", "钱沈云 RWR 代码回代 SensM_M", "同一位移边界下比钱沈云程序/论文输出"),
    @("2 mm 反算表", "当前 results_static.csv 新口径", "旧表作废，重生成新表")
)
Add-Table $slide 52 156 856 196 $headers $rows 10.5 | Out-Null
Add-Text $slide 58 386 840 56 "定位到的钱沈云回代结构：Main_StaticNL851T5T56MEEP_RWR_V4.m 中先迭代得到 Qd1，再通过耦合矩阵解 SensM_E / SensM_M。下一步就围绕这里闭环。" 15 $true $script:BrandBlue | Out-Null

# Slide 7
$slide = $pres.Slides.Add(7, 12)
Add-Header $slide "本周处理方案" 7
Add-Card $slide 44 82 260 128 "Step 1" "保留力加载位移验证：原始 4.93%，刚度敏感性 2.72%，明确 3% 口径还要解释。" $script:BrandBlue
Add-Card $slide 350 82 260 128 "Step 2" "把 300 V / 200 A 与钱沈云 Table 4 / Table 5 的对照作为本周最稳结果。" $script:Green
Add-Card $slide 656 82 260 128 "Step 3" "下一步重跑位移回代电/磁势，旧 2 mm 表作废，形成新口径外部误差表。" $script:Amber
Add-Text $slide 58 256 842 42 "这周 PPT 建议主线：最新材料入库 → 五点状态矩阵 → 第二点已对上 → 第一点仍需 3% 解释 → 第三点作为下周闭环。" 17 $true $script:Ink | Out-Null
$headers = @("原 PPT 内容", "处理后去向")
$rows = @(
    @("研究对象与模型参数", "保留，用作背景"),
    @("2 mm 耦合表", "旧表作废，只保留新缩放值和重跑计划"),
    @("MATLAB-COMSOL 位移表", "放到第一点，说明可用但未严格 3%"),
    @("电/磁致变形结果", "升级为第二点主证据，与钱沈云表格同页展示"),
    @("静力参数扫描、磁电效率", "暂放附录，不作为本周结论"),
    @("含孔隙/动力/论文结果", "暂不主讲，避免验证未闭环前过度展开")
)
Add-Table $slide 72 326 816 156 $headers $rows 10.5 | Out-Null

# Slide 8
$slide = $pres.Slides.Add(8, 12)
Add-Header $slide "处理后的汇报口径" 8
Add-SectionLabel $slide 54 76 "可以直接说" $script:Green
Add-Text $slide 72 126 820 78 "1. 电压/磁势致变形已经与钱沈云论文 Table 4/Table 5 基本一致，误差约 1% 内。`n2. 力-位移链路已有 COMSOL 对照，原始最大 4.93%，敏感性后 2.72%。`n3. 第三点位移回代电/磁势是下一步闭环。" 16 $true $script:Ink | Out-Null
Add-SectionLabel $slide 54 246 "不要直接说" $script:Red
Add-Text $slide 72 296 820 70 "1. 不要说第一点已经严格外部验证到 3% 内。`n2. 不要继续使用旧 2 mm 表的 90075 V / 17974 A。`n3. 不要把第三点写成已完成。" 16 $true $script:Ink | Out-Null
Add-Text $slide 72 424 812 36 "一句话版本：第二点已经对上，第一点还差 3% 口径，第三点下周闭环。" 17 $true $script:BrandBlue "center" | Out-Null

# Slide 9
$slide = $pres.Slides.Add(9, 12)
Add-Text $slide 34 22 170 34 "上海大学" 16 $true $script:BrandBlue | Out-Null
$box = $slide.Shapes.AddShape(1, 50, 190, 860, 105)
$box.Fill.ForeColor.RGB = $script:BrandBlue
$box.Line.Visible = 0
Add-Text $slide 50 224 860 42 "恳请各位批评指正" 26 $true (OleColor 255 255 0) "center" | Out-Null
Add-Text $slide 50 324 860 30 "附：五点更新矩阵已生成，下一步闭环位移回代电/磁势" 15 $true $script:Ink "center" | Out-Null

$pres.SaveAs($pptPath, 24)
$pres.SaveAs($pdfPath, 32)
$pres.Close()
$app.Quit()

"PPTX=$pptPath"
"PDF=$pdfPath"
