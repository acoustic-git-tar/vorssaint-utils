// SPDX-License-Identifier: GPL-3.0-or-later
// Copyright (C) 2026 Vorssaint

struct DockLockStrings {
    let title: String
    let enable: String
    let caption: String
    let display: String
    let main: String
    let bypass: String
    let bypassCaption: String
    let disconnectedDisplay: String
    let disconnected: String
    let covered: String
    let note: String

    static func localized(_ language: AppLanguage) -> DockLockStrings {
        switch language {
        case .enUS: return .init(
            title: "Dock Locking",
            enable: "Lock Dock to a display",
            caption: "Keep the Dock on the selected display when the pointer reaches another screen’s edge.",
            display: "Lock Dock to",
            main: "System Main Display",
            bypass: "Bypass modifier key",
            bypassCaption: "Hold this key to temporarily allow the Dock to move freely.",
            disconnectedDisplay: "Disconnected Display",
            disconnected: "Locking is paused until this display reconnects.",
            covered: "Another display covers this display’s Dock edge. Rearrange displays in System Settings → Displays to leave part of that edge free.",
            note: "The Dock moves to the selected display automatically. System Main Display follows the menu bar. Works best with a bottom Dock and “Displays have separate Spaces” enabled in System Settings → Desktop & Dock → Mission Control.")
        case .ptBR: return .init(
            title: "Bloqueio do Dock",
            enable: "Fixar o Dock em uma tela",
            caption: "Mantenha o Dock na tela selecionada quando o ponteiro atingir a borda de outra tela.",
            display: "Fixar o Dock em",
            main: "Tela principal do sistema",
            bypass: "Tecla para liberar",
            bypassCaption: "Segure esta tecla para permitir que o Dock se mova livremente.",
            disconnectedDisplay: "Tela desconectada",
            disconnected: "O bloqueio está pausado até esta tela se reconectar.",
            covered: "Outra tela cobre a borda do Dock desta tela. Reorganize as telas em Ajustes do Sistema → Telas para liberar parte dessa borda.",
            note: "O Dock vai automaticamente para a tela selecionada. A tela principal acompanha a barra de menus. Funciona melhor com o Dock embaixo e “As telas têm Spaces separados” ativado em Ajustes do Sistema → Mesa e Dock → Mission Control.")
        case .es: return .init(
            title: "Bloqueo del Dock",
            enable: "Fijar el Dock a una pantalla",
            caption: "Mantén el Dock en la pantalla elegida cuando el puntero llegue al borde de otra pantalla.",
            display: "Fijar el Dock a",
            main: "Pantalla principal del sistema",
            bypass: "Tecla para omitir el bloqueo",
            bypassCaption: "Mantén pulsada esta tecla para que el Dock se mueva libremente.",
            disconnectedDisplay: "Pantalla desconectada",
            disconnected: "El bloqueo se pausa hasta que esta pantalla se reconecte.",
            covered: "Otra pantalla cubre el borde del Dock de esta pantalla. Reorganiza las pantallas en Ajustes del Sistema → Pantallas para dejar libre parte del borde.",
            note: "El Dock se mueve automáticamente a la pantalla elegida. La pantalla principal sigue a la barra de menús. Funciona mejor con el Dock abajo y “Las pantallas tienen Spaces separados” activado en Ajustes del Sistema → Escritorio y Dock → Mission Control.")
        case .fr: return .init(
            title: "Verrouillage du Dock",
            enable: "Fixer le Dock à un écran",
            caption: "Gardez le Dock sur l’écran choisi lorsque le pointeur atteint le bord d’un autre écran.",
            display: "Fixer le Dock à",
            main: "Écran principal du système",
            bypass: "Touche de contournement",
            bypassCaption: "Maintenez cette touche pour permettre au Dock de se déplacer librement.",
            disconnectedDisplay: "Écran déconnecté",
            disconnected: "Le verrouillage est suspendu jusqu’à la reconnexion de cet écran.",
            covered: "Un autre écran couvre le bord du Dock de cet écran. Réorganisez les écrans dans Réglages Système → Moniteurs pour libérer une partie de ce bord.",
            note: "Le Dock se déplace automatiquement vers l’écran choisi. L’écran principal suit la barre des menus. Fonctionne mieux avec le Dock en bas et « Les écrans disposent de Spaces distincts » activé dans Réglages Système → Bureau et Dock → Mission Control.")
        case .de: return .init(
            title: "Dock-Sperre",
            enable: "Dock an einen Bildschirm binden",
            caption: "Das Dock bleibt auf dem gewählten Bildschirm, wenn der Zeiger den Rand eines anderen Bildschirms erreicht.",
            display: "Dock binden an",
            main: "Hauptbildschirm des Systems",
            bypass: "Taste zum Umgehen",
            bypassCaption: "Halte diese Taste, damit sich das Dock vorübergehend frei bewegen kann.",
            disconnectedDisplay: "Bildschirm getrennt",
            disconnected: "Die Sperre pausiert, bis dieser Bildschirm wieder verbunden ist.",
            covered: "Ein anderer Bildschirm verdeckt den Dock-Rand dieses Bildschirms. Ordne die Bildschirme unter Systemeinstellungen → Displays so an, dass ein Teil des Randes frei bleibt.",
            note: "Das Dock wechselt automatisch zum gewählten Bildschirm. Der Hauptbildschirm folgt der Menüleiste. Funktioniert am besten mit dem Dock unten und aktivierter Option „Monitore verwenden verschiedene Spaces“ unter Systemeinstellungen → Schreibtisch & Dock → Mission Control.")
        case .it: return .init(
            title: "Blocco del Dock",
            enable: "Fissa il Dock a uno schermo",
            caption: "Mantieni il Dock sullo schermo scelto quando il puntatore raggiunge il bordo di un altro schermo.",
            display: "Fissa il Dock a",
            main: "Schermo principale del sistema",
            bypass: "Tasto per ignorare il blocco",
            bypassCaption: "Tieni premuto questo tasto per consentire al Dock di spostarsi liberamente.",
            disconnectedDisplay: "Schermo scollegato",
            disconnected: "Il blocco è sospeso finché questo schermo non viene ricollegato.",
            covered: "Un altro schermo copre il bordo del Dock di questo schermo. Riordina gli schermi in Impostazioni di Sistema → Schermi per liberare parte del bordo.",
            note: "Il Dock si sposta automaticamente sullo schermo scelto. Lo schermo principale segue la barra dei menu. Funziona meglio con il Dock in basso e “Gli schermi hanno spazi separati” attivo in Impostazioni di Sistema → Scrivania e Dock → Mission Control.")
        case .ja: return .init(
            title: "Dockの固定",
            enable: "Dockをディスプレイに固定",
            caption: "ポインタが別の画面の端に達しても、Dockを選択したディスプレイに保ちます。",
            display: "固定先",
            main: "システムのメインディスプレイ",
            bypass: "固定を一時解除するキー",
            bypassCaption: "このキーを押している間、Dockを自由に移動できます。",
            disconnectedDisplay: "未接続のディスプレイ",
            disconnected: "このディスプレイが再接続されるまで固定を一時停止します。",
            covered: "別のディスプレイがDock側の端を塞いでいます。システム設定 → ディスプレイで配置を変更し、端の一部を空けてください。",
            note: "Dockは選択したディスプレイに自動的に移動します。メインディスプレイはメニューバーに従います。Dockを下に配置し、システム設定 → デスクトップとDock → Mission Controlで「ディスプレイごとに個別の操作スペース」を有効にすると最適に動作します。")
        case .ko: return .init(
            title: "Dock 고정",
            enable: "Dock을 디스플레이에 고정",
            caption: "포인터가 다른 화면 가장자리에 닿아도 Dock을 선택한 디스플레이에 유지합니다.",
            display: "Dock 고정 위치",
            main: "시스템 주 디스플레이",
            bypass: "고정 해제 보조 키",
            bypassCaption: "이 키를 누르는 동안 Dock을 자유롭게 이동할 수 있습니다.",
            disconnectedDisplay: "연결되지 않은 디스플레이",
            disconnected: "이 디스플레이가 다시 연결될 때까지 고정이 일시 정지됩니다.",
            covered: "다른 디스플레이가 이 화면의 Dock 가장자리를 가립니다. 시스템 설정 → 디스플레이에서 배치를 바꿔 가장자리 일부를 비워 주세요.",
            note: "Dock이 선택한 디스플레이로 자동 이동합니다. 주 디스플레이는 메뉴 막대를 따릅니다. Dock을 아래에 놓고 시스템 설정 → 데스크탑 및 Dock → Mission Control에서 “각각의 Spaces가 있는 디스플레이”를 켜면 가장 잘 작동합니다.")
        case .zhHans: return .init(
            title: "锁定 Dock",
            enable: "将 Dock 固定到显示器",
            caption: "指针到达其他屏幕边缘时，让 Dock 留在所选显示器上。",
            display: "Dock 固定位置",
            main: "系统主显示器",
            bypass: "临时解除修饰键",
            bypassCaption: "按住此键可暂时允许 Dock 自由移动。",
            disconnectedDisplay: "未连接的显示器",
            disconnected: "此显示器重新连接前，锁定将暂停。",
            covered: "另一台显示器挡住了此显示器的 Dock 边缘。请在系统设置 → 显示器中重新排列，让部分边缘露出。",
            note: "Dock 会自动移至所选显示器。系统主显示器跟随菜单栏。将 Dock 放在底部，并在系统设置 → 桌面与程序坞 → 调度中心启用“显示器具有单独的空间”时效果最佳。")
        case .zhTW: return .init(
            title: "鎖定 Dock",
            enable: "將 Dock 固定到顯示器",
            caption: "指標到達其他螢幕邊緣時，讓 Dock 留在所選顯示器上。",
            display: "Dock 固定位置",
            main: "系統主要顯示器",
            bypass: "暫時解除輔助鍵",
            bypassCaption: "按住此鍵可暫時允許 Dock 自由移動。",
            disconnectedDisplay: "未連接的顯示器",
            disconnected: "此顯示器重新連接前，鎖定將暫停。",
            covered: "另一台顯示器擋住了此顯示器的 Dock 邊緣。請在系統設定 → 顯示器中重新排列，讓部分邊緣露出。",
            note: "Dock 會自動移至所選顯示器。系統主要顯示器跟隨選單列。將 Dock 放在底部，並在系統設定 → 桌面與 Dock → 指揮中心啟用「顯示器具有個別的空間」時效果最佳。")
        case .zhHK: return .init(
            title: "鎖定 Dock",
            enable: "將 Dock 固定到顯示器",
            caption: "指標到達其他螢幕邊緣時，讓 Dock 留在所選顯示器上。",
            display: "Dock 固定位置",
            main: "系統主要顯示器",
            bypass: "暫時解除輔助鍵",
            bypassCaption: "按住此鍵可暫時允許 Dock 自由移動。",
            disconnectedDisplay: "未連接的顯示器",
            disconnected: "此顯示器重新連接前，鎖定將暫停。",
            covered: "另一部顯示器擋住了此顯示器的 Dock 邊緣。請在系統設定 → 顯示器中重新排列，讓部分邊緣露出。",
            note: "Dock 會自動移至所選顯示器。系統主要顯示器跟隨選單列。將 Dock 放在底部，並在系統設定 → 桌面與 Dock → Mission Control 啟用「顯示器具有個別的空間」時效果最佳。")
        case .ru: return .init(
            title: "Закрепление Dock",
            enable: "Закрепить Dock на дисплее",
            caption: "Dock остаётся на выбранном дисплее, когда указатель достигает края другого экрана.",
            display: "Закрепить Dock на",
            main: "Основной дисплей системы",
            bypass: "Клавиша обхода",
            bypassCaption: "Удерживайте эту клавишу, чтобы временно разрешить свободное перемещение Dock.",
            disconnectedDisplay: "Отключённый дисплей",
            disconnected: "Закрепление приостановлено до подключения этого дисплея.",
            covered: "Другой дисплей закрывает край Dock этого дисплея. Измените расположение в Системных настройках → Дисплеи, чтобы освободить часть края.",
            note: "Dock автоматически перемещается на выбранный дисплей. Основной дисплей следует за строкой меню. Лучше работает с Dock внизу и включёнными отдельными пространствами дисплеев в Системных настройках → Рабочий стол и Dock → Mission Control.")
        case .uk: return .init(
            title: "Закріплення Dock",
            enable: "Закріпити Dock на дисплеї",
            caption: "Dock залишається на вибраному дисплеї, коли вказівник досягає краю іншого екрана.",
            display: "Закріпити Dock на",
            main: "Основний дисплей системи",
            bypass: "Клавіша обходу",
            bypassCaption: "Утримуйте цю клавішу, щоб тимчасово дозволити вільне переміщення Dock.",
            disconnectedDisplay: "Від’єднаний дисплей",
            disconnected: "Закріплення призупинено до підключення цього дисплея.",
            covered: "Інший дисплей закриває край Dock цього дисплея. Змініть розташування в Системних параметрах → Дисплеї, щоб звільнити частину краю.",
            note: "Dock автоматично переміщується на вибраний дисплей. Основний дисплей відповідає смузі меню. Найкраще працює з Dock унизу й окремими просторами дисплеїв у Системних параметрах → Робочий стіл і Dock → Mission Control.")
        case .sk: return .init(
            title: "Uzamknutie Docku",
            enable: "Pripnúť Dock k displeju",
            caption: "Dock zostane na zvolenom displeji, keď kurzor dosiahne okraj inej obrazovky.",
            display: "Pripnúť Dock k",
            main: "Hlavný displej systému",
            bypass: "Kláves na obídenie",
            bypassCaption: "Podržte tento kláves a dočasne povoľte voľný pohyb Docku.",
            disconnectedDisplay: "Odpojený displej",
            disconnected: "Uzamknutie je pozastavené, kým sa tento displej znova nepripojí.",
            covered: "Iný displej zakrýva okraj Docku tohto displeja. Upravte rozloženie v Systémové nastavenia → Displeje, aby časť okraja zostala voľná.",
            note: "Dock sa automaticky presunie na zvolený displej. Hlavný displej sleduje lištu. Najlepšie funguje s Dockom dole a samostatnými priestormi displejov v Systémové nastavenia → Plocha a Dock → Mission Control.")
        case .tr: return .init(
            title: "Dock Kilitleme",
            enable: "Dock’u bir ekrana sabitle",
            caption: "İşaretçi başka bir ekranın kenarına ulaştığında Dock seçilen ekranda kalır.",
            display: "Dock’un sabitleneceği ekran",
            main: "Sistemin ana ekranı",
            bypass: "Kilidi aşma tuşu",
            bypassCaption: "Dock’un geçici olarak serbestçe taşınması için bu tuşu basılı tutun.",
            disconnectedDisplay: "Bağlantısı kesilmiş ekran",
            disconnected: "Bu ekran yeniden bağlanana kadar kilitleme duraklatılır.",
            covered: "Başka bir ekran bu ekranın Dock kenarını kapatıyor. Kenarın bir kısmını boş bırakmak için Sistem Ayarları → Ekranlar’da ekranları yeniden düzenleyin.",
            note: "Dock seçilen ekrana otomatik taşınır. Ana ekran menü çubuğunu izler. Dock alttayken ve Sistem Ayarları → Masaüstü ve Dock → Mission Control’de ekranların ayrı alanları etkinleştirildiğinde en iyi sonucu verir.")
        }
    }
}
