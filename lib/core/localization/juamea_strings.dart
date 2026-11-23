import 'juamea_language.dart';

/// Strongly-typed trilingual dictionary (FR / EN / SW) for Juamea — East Africa.
class JuameaStrings {
  const JuameaStrings._();

  static JuameaStringsData of(JuameaLanguage lang) {
    switch (lang) {
      case JuameaLanguage.en:
        return _en;
      case JuameaLanguage.sw:
        return _sw;
      case JuameaLanguage.fr:
        return _fr;
    }
  }

  static const JuameaStringsData _fr = JuameaStringsData(
    language: JuameaLanguage.fr,
    // Language selector
    selectLanguageTitle: 'Choisir la langue',
    selectLanguageSubtitle:
        "L'interface et les réponses IA de Juamea s'adaptent instantanément.",
    languageTooltip: 'Langue (FR / EN / SW)',

    // Initialization screen
    initSubtitle: "Agronome IA 100 % hors ligne pour l'Afrique de l'Est",
    initChecking: "Vérification des ressources d'intelligence locale...",
    initConnectionStatusTitle: 'Statut de la connexion',
    initErrorNetwork:
        "La connexion avec le serveur a été interrompue. Appuyez sur Reprendre pour continuer le téléchargement exactement là où il s'est arrêté.",
    initErrorServer:
        "Nos serveurs de téléchargement sécurisés sont actuellement occupés. Réessayez dans quelques secondes.",
    initErrorGeneric:
        "Un léger contretemps est survenu lors de la configuration. Appuyez sur Reprendre pour continuer.",
    initCardTitle: 'SautiLM-Jua-Agri (Chat IA hors ligne)',
    initConnectingDesc:
        "Connexion au dépôt sécurisé Hugging Face. Les poids (~283 Mo) sont stockés dans le coffre privé de Juamea et supprimés automatiquement si vous désinstallez l'application.",
    initCheckingConnectionBtn: 'Vérification...',
    initDownloadDesc:
        "Téléchargement optionnel (~283 Mo) dans le coffre privé Juamea (auto-nettoyé à la désinstallation). Le scan foliaire SautiLM-Nuru-Agri et les 2 369 fiches FAO/NARS sont déjà intégrés hors ligne.",
    initKeepOpenNotice:
        "Gardez l'application ouverte jusqu'à la fin du téléchargement.",
    initDownloadBtn: "Télécharger l'IA",
    initSkipBtn: 'Continuer sans IA',
    initPausedTitle: 'Configuration en pause',
    initPausedBadge: 'Interrompu',
    initPausedDesc:
        "La configuration a été interrompue. Vérifiez votre connexion Internet puis appuyez sur Reprendre.",
    initResumeBtn: 'Reprendre',
    okBtn: 'OK',

    // Navigation & Scan Source Sheet
    navHome: 'Accueil',
    scanSheetTitle: 'Scanner une feuille',
    scanSheetSubtitle:
        "Analysez une photo réelle de votre culture hors ligne avec SautiLM-Nuru-Agri.",
    takePhotoTitle: 'Prendre une photo',
    takePhotoSubtitle: 'Capturer une feuille en direct avec la caméra',
    choosePhotoTitle: 'Choisir une photo',
    choosePhotoSubtitle: 'Importer une photo réelle depuis votre galerie',
    imageOpenErrorPrefix: "Impossible d'ouvrir l'image",
    scanDoneSnack:
        "Analyse terminée ! Un nouveau diagnostic est disponible dans Accueil.",
    scanInterruptedPrefix: 'Analyse interrompue',

    // Home dashboard
    homeGreeting: 'Jambo ! 👋🏾',
    homeSubtitle: "Votre ferme en Afrique de l'Est, protégée hors ligne.",
    modelsTooltip: 'Moteurs IA & Stockage Privé',
    pdfTooltip: 'Exporter le Rapport PDF',
    historyTooltip: 'Historique des diagnostics',
    lastDiagnosticTitle: 'Dernier Diagnostic',
    noScanYet: 'Aucun scan effectué',
    tapScannerHint: 'Appuyez sur scanneur',
    confidenceSuffix: 'de confiance',
    waterScheduleTitle: "Programme d'Eau",
    rainPausedTitle: 'Pluie - Calendrier en pause',
    irrigationActiveTitle: 'Irrigation active',
    waterAllIrrigated: 'Toutes les cultures sont irriguées',
    waterNextPrefix: 'Prochain',
    waterOnDateWord: 'le',
    waterRainPausedStatus: 'Pluie prévue - Irrigation en pause',
    soilRemindersTitle: 'Rappels du Sol',
    reminderCassavaMosaic:
        'Vérifiez les herbes sauvages et mouches blanches dans vos champs de manioc.',
    reminderMaizeRust:
        'Vaporisez une solution de neem sur les cultures de maïs.',
    reminderRainTomorrow:
        "Pluie demain ! Gardez les seaux d'engrais à l'abri.",
    reminderDrySoil:
        "Alerte sol sec. Surveillez le niveau d'humidité du maïs.",
    irrigationCalendarTitle: "Calendrier d'Irrigation",
    autonomousAdjustLabel: 'Ajustement autonome actif',
    dateLabel: 'Date : ',
    rainSwitchLabel: 'Pluie ',
    retryBtn: 'Réessayer',

    // PDF Sheet
    pdfSheetTitle: 'Rapport de Productivité (PDF)',
    pdfSheetSubtitle:
        'Choisissez une option pour exporter votre rapport agronomique.',
    pdfSavedSnackPrefix: 'Rapport PDF enregistré dans vos Documents',
    pdfOpenBtn: 'Ouvrir',
    pdfDownloadTitle: 'Télécharger le PDF',
    pdfDownloadSubtitle:
        'Enregistrer dans le dossier Documents du téléphone',
    pdfShareTitle: 'Partager le PDF',
    pdfShareSubtitle: 'Envoyer via WhatsApp, Email, Drive ou Bluetooth',
    pdfDownloadErrorPrefix: 'Erreur lors du téléchargement',
    pdfShareErrorPrefix: 'Erreur lors du partage',

    // Chat
    chatWelcome:
        "Jambo 👋🏾 ! Je suis Juamea, votre assistant agronome 100 % hors ligne pour l'Afrique de l'Est. Posez-moi vos questions sur le manioc, le maïs, les pesticides biologiques à base de neem ou la pluie pour ajuster votre calendrier d'irrigation !",
    chatMissingModelPrompt:
        "Le modèle IA SautiLM-Jua-Agri n'est pas encore téléchargé sur cet appareil. Appuyez sur « Télécharger le modèle » pour activer le chat hors ligne.",
    chatMissingBannerText: 'Modèle IA requis pour le chat hors ligne.',
    chatDownloadBtnShort: 'Télécharger',
    chatDownloadBtnFull: 'Télécharger le modèle',
    chatModelTooltip: 'Modèle IA',
    chatClearTooltip: 'Effacer les discussions',
    chatClearTitle: 'Supprimer la discussion ?',
    chatClearBody:
        "Êtes-vous sûr de vouloir effacer tout l'historique de cette conversation ? Cette action est irréversible.",
    cancelBtn: 'Annuler',
    deleteBtn: 'Supprimer',
    faoBadgeLabel: 'Ancré FAO RAG',
    stopLabel: 'STOP',
    listenLabel: 'Écouter',
    micListeningTooltip: 'Écoute en cours...',
    micVoiceTooltip: 'Dictée vocale',
    chatInputHint: 'Posez une question sur vos cultures...',
    chatRainAdjustedNotice:
        "Calendrier ajusté : Arrosage mis en pause suite au signalement de pluie.",
    chatDryAdjustedNotice:
        "Calendrier ajusté : Arrosage régulier programmé pour temps sec.",
    chatBusyPlaceholder:
        "Je vais vous répondre une fois l'analyse de votre feuille terminée...",
    chatEmptyFallback:
        "Je ne peux pas répondre pour l'instant, veuillez réessayer.",
    chatErrorFallback:
        "Je ne peux pas répondre pour l'instant, veuillez réessayer ou vérifier le modèle IA local.",

    // Model modal
    modelModalTitle: 'Moteurs IA & Stockage Privé',
    modelModalStoreNote:
        "Conforme Play Store & App Store : zéro permission de stockage externe. Tous les poids téléchargés sont automatiquement effacés si vous désinstallez Juamea.",
    modelNuruTitle: 'SautiLM-Nuru-Agri (1,07 Mo) + SQLite FAO/NARS',
    modelNuruDesc:
        "Intégré dans l'application : scan foliaire 9 classes + 2 369 fiches agronomiques d'Afrique de l'Est 100 % hors ligne.",
    modelJuaTitle: 'SautiLM-Jua-Agri (Chat IA)',
    modelNotInstalledBadge: 'Non installé',
    modelVaultPrefix: 'Coffre privé sécurisé',
    modelOptionalDesc:
        'Modèle optionnel (~283 Mo) pour les réponses conversationnelles avancées hors ligne.',
    modelCheckShaNotice: 'Vérification SHA-256 Hugging Face (< 2 Ko)...',
    modelUpToDateMsg: 'SautiLM-Jua-Agri est déjà à jour',
    modelUpdateAvailableMsg: 'Nouvelle version disponible sur Hugging Face',
    modelNotInstalledMsg: 'Modèle chat non encore téléchargé',
    modelOfflineCheckMsg:
        'Hors ligne : connectez-vous brièvement pour vérifier Hugging Face.',
    modelCheckErrorPrefix: 'Erreur de vérification',
    modelUpdatingStatus:
        'Mise à jour de SautiLM-Jua-Agri depuis Hugging Face...',
    modelDownloadingStatus:
        'Téléchargement de SautiLM-Jua-Agri dans le coffre privé...',
    modelInstalledMsg:
        'SautiLM-Jua-Agri installé et vérifié dans le coffre privé !',
    modelInterruptedMsg:
        'Téléchargement interrompu : vérifiez votre connexion Internet.',
    modelDeleteConfirmTitle: 'Supprimer le modèle chat local ?',
    modelDeleteConfirmBodyPrefix: 'Cette action libère immédiatement',
    modelDeleteConfirmBodySuffix:
        "en supprimant SautiLM-Jua-Agri du coffre privé.\n\nLe scan foliaire SautiLM-Nuru-Agri (1,07 Mo) et les 2 369 fiches FAO/NARS restent 100 % fonctionnels hors ligne.",
    modelFreeingSpaceMsg: 'Libération du stockage local...',
    modelDeletedMsg: 'Modèle chat supprimé. Espace de stockage libéré.',
    modelUpdateBtn: 'Mettre à jour',
    modelUpToDateBtn: 'Modèle à jour',
    modelCheckUpdateBtn: 'Vérifier mise à jour',
    modelDeleteBtn: 'Supprimer le modèle',

    // Scan result modal & ScanCubit
    scanModalTitlePrefix: 'Analyse de Culture ',
    scanBackgroundSnack:
        "Analyse IA en cours en arrière-plan... Le résultat sera disponible dans Accueil.",
    scanProcessingMsg: 'SautiLM-Nuru-Agri analyse la feuille hors ligne...',
    scanCanCloseHint:
        "Vous pouvez fermer cet écran pour continuer d'utiliser l'application.",
    scanResultHeader: 'Diagnostic et Remède Local :',
    scanNotLeafTitle: 'Feuille non détectée',
    scanNotLeafMessage:
        "L'image capturée ne semble pas être une feuille de plante. Veuillez reprendre une photo en ciblant clairement une feuille de votre culture.",
    scanErrorTitle: 'Une erreur est survenue',
    scanErrorMessage:
        "L'analyse IA n'a pas pu se terminer sur votre appareil. Réessayez avec une photo bien éclairée.",
    scanRetakeBtn: 'Reprendre la photo',
    scanRetryBtn: 'Fermer & Réessayer',

    // History page
    historyTitle: 'Historique des Diagnostics',
    historyEmptyTitle: 'Aucun diagnostic de plante',
    historyEmptyDesc:
        "Utilisez l'icône appareil photo pour scanner vos feuilles de culture. Vos diagnostics apparaîtront ici.",
    historyNewBadge: 'NOUVEAU',
    historyCropLabel: 'Culture',
    historyImpactTitle: "Estimation d'Impact Économique & Perte Évitée",
    historyImpactBody:
        "Risque de perte non traité : ~40 % à 70 % du rendement par hectare.\nGain estimé après application du traitement FAO : +120 \$ à +350 \$/ha.",
    historyRemediesTitle: 'Actions correctives recommandées (FAO / IITA) :',
    historyExportPdfBtn: 'Exporter PDF',
    historyDeleteDialogTitle: 'Supprimer ?',
    historyDeleteDialogBodyPrefix:
        'Êtes-vous sûr de vouloir supprimer ce diagnostic du',
    historyDeleteDialogBodySuffix: 'Cette action est irréversible.',
    historyDeletedSnack: 'Diagnostic supprimé avec succès.',
    historyExportSingleTitlePrefix: 'Exporter Diagnostic PDF',
    historyExportSingleSubtitle:
        'Choisissez une option pour sauvegarder ou partager ce diagnostic.',
    historySingleSavedPrefix: 'Diagnostic PDF enregistré dans vos Documents',
    historyShareOrPrintTitle: 'Partager ou Imprimer le PDF',
    historyShareOrPrintSubtitle:
        'Envoyer via WhatsApp, Email ou imprimer directement',
    atTimeWord: 'à',
  );

  static const JuameaStringsData _en = JuameaStringsData(
    language: JuameaLanguage.en,
    selectLanguageTitle: 'Choose Language',
    selectLanguageSubtitle:
        "Juamea's interface and AI responses adapt immediately.",
    languageTooltip: 'Language (FR / EN / SW)',

    initSubtitle: '100% offline AI agronomist for East Africa',
    initChecking: 'Checking local intelligence resources...',
    initConnectionStatusTitle: 'Connection status',
    initErrorNetwork:
        'Connection was interrupted. Tap Resume to continue downloading right where it left off.',
    initErrorServer:
        'Our secure download servers are busy right now. Please try again in a few seconds.',
    initErrorGeneric:
        'A minor setup hiccup occurred. Tap Resume to continue.',
    initCardTitle: 'SautiLM-Jua-Agri (Offline AI Chat)',
    initConnectingDesc:
        'Connecting to Hugging Face secure storage. Weights (~283 MB) are stored in Juamea private vault and automatically deleted on uninstall.',
    initCheckingConnectionBtn: 'Checking...',
    initDownloadDesc:
        'Optional download (~283 MB) in Juamea private vault (auto-cleaned on uninstall). SautiLM-Nuru-Agri leaf scan and 2,369 FAO/NARS sheets are already built in offline.',
    initKeepOpenNotice:
        'Keep the app open until the download finishes.',
    initDownloadBtn: 'Download AI',
    initSkipBtn: 'Continue without AI',
    initPausedTitle: 'Setup paused',
    initPausedBadge: 'Paused',
    initPausedDesc:
        'Setup was interrupted. Check your internet connection, then tap Resume.',
    initResumeBtn: 'Resume',
    okBtn: 'OK',

    navHome: 'Home',
    scanSheetTitle: 'Scan a leaf',
    scanSheetSubtitle:
        'Analyze a real photo of your crop offline with SautiLM-Nuru-Agri.',
    takePhotoTitle: 'Take a photo',
    takePhotoSubtitle: 'Capture a leaf live with your camera',
    choosePhotoTitle: 'Choose a photo',
    choosePhotoSubtitle: 'Import a real photo from your gallery',
    imageOpenErrorPrefix: 'Unable to open image',
    scanDoneSnack:
        'Analysis complete! A new diagnostic is available on Home.',
    scanInterruptedPrefix: 'Analysis interrupted',

    homeGreeting: 'Jambo! 👋🏾',
    homeSubtitle: 'Your East African farm, protected 100% offline.',
    modelsTooltip: 'AI Engines & Private Vault',
    pdfTooltip: 'Export PDF Report',
    historyTooltip: 'Diagnostics History',
    lastDiagnosticTitle: 'Last Diagnostic',
    noScanYet: 'No scan yet',
    tapScannerHint: 'Tap scanner button',
    confidenceSuffix: 'confidence',
    waterScheduleTitle: 'Water Schedule',
    rainPausedTitle: 'Rain - Schedule paused',
    irrigationActiveTitle: 'Irrigation active',
    waterAllIrrigated: 'All crops are irrigated',
    waterNextPrefix: 'Next',
    waterOnDateWord: 'on',
    waterRainPausedStatus: 'Rain expected - Irrigation paused',
    soilRemindersTitle: 'Soil Reminders',
    reminderCassavaMosaic:
        'Check for weeds and whiteflies across your cassava plots.',
    reminderMaizeRust:
        'Spray an organic neem solution on affected maize leaves.',
    reminderRainTomorrow:
        'Rain expected! Keep fertilizer bags dry and sheltered.',
    reminderDrySoil:
        'Dry soil alert. Monitor soil moisture around maize roots.',
    irrigationCalendarTitle: 'Irrigation Calendar',
    autonomousAdjustLabel: 'Auto-adjust active',
    dateLabel: 'Date: ',
    rainSwitchLabel: 'Rain ',
    retryBtn: 'Retry',

    pdfSheetTitle: 'Productivity Report (PDF)',
    pdfSheetSubtitle:
        'Choose how to export your agronomic field report.',
    pdfSavedSnackPrefix: 'PDF report saved in Documents',
    pdfOpenBtn: 'Open',
    pdfDownloadTitle: 'Download PDF',
    pdfDownloadSubtitle: 'Save into your phone Documents folder',
    pdfShareTitle: 'Share PDF',
    pdfShareSubtitle: 'Send via WhatsApp, Email, Drive or Bluetooth',
    pdfDownloadErrorPrefix: 'Download error',
    pdfShareErrorPrefix: 'Share error',

    chatWelcome:
        "Jambo 👋🏾! I'm Juamea, your 100% offline AI agronomist for East Africa. Ask me about cassava, maize spacing, organic neem remedies, or rain updates to adjust your irrigation calendar!",
    chatMissingModelPrompt:
        'The SautiLM-Jua-Agri AI model is not downloaded on this device yet. Tap "Download model" to enable offline chat.',
    chatMissingBannerText: 'AI model required for offline chat.',
    chatDownloadBtnShort: 'Download',
    chatDownloadBtnFull: 'Download model',
    chatModelTooltip: 'AI Model',
    chatClearTooltip: 'Clear chat',
    chatClearTitle: 'Clear conversation?',
    chatClearBody:
        'Are you sure you want to delete all messages in this chat? This cannot be undone.',
    cancelBtn: 'Cancel',
    deleteBtn: 'Delete',
    faoBadgeLabel: 'FAO RAG Grounded',
    stopLabel: 'STOP',
    listenLabel: 'Listen',
    micListeningTooltip: 'Listening...',
    micVoiceTooltip: 'Voice input',
    chatInputHint: 'Ask about your crops, pests, or rain...',
    chatRainAdjustedNotice:
        'Calendar updated: Irrigation paused due to reported rain.',
    chatDryAdjustedNotice:
        'Calendar updated: Regular irrigation resumed for dry weather.',
    chatBusyPlaceholder:
        'I will reply right after your leaf scan finishes...',
    chatEmptyFallback:
        'I cannot answer right now, please try again.',
    chatErrorFallback:
        'I cannot answer right now. Please try again or check your local AI model.',

    modelModalTitle: 'AI Engines & Private Vault',
    modelModalStoreNote:
        'Play Store & App Store compliant: zero external storage permissions. Downloaded weights are automatically removed if you uninstall Juamea.',
    modelNuruTitle: 'SautiLM-Nuru-Agri (1.07 MB) + FAO/NARS SQLite',
    modelNuruDesc:
        'Built into the app: 9-class leaf scanner + 2,369 East African agronomic records 100% offline.',
    modelJuaTitle: 'SautiLM-Jua-Agri (AI Chat)',
    modelNotInstalledBadge: 'Not installed',
    modelVaultPrefix: 'Secure private vault',
    modelOptionalDesc:
        'Optional model (~283 MB) for advanced offline conversational agronomy.',
    modelCheckShaNotice: 'Checking Hugging Face SHA-256 (< 2 KB)...',
    modelUpToDateMsg: 'SautiLM-Jua-Agri is already up to date',
    modelUpdateAvailableMsg: 'New version available on Hugging Face',
    modelNotInstalledMsg: 'Chat model not downloaded yet',
    modelOfflineCheckMsg:
        'Offline: connect briefly to check Hugging Face updates.',
    modelCheckErrorPrefix: 'Check error',
    modelUpdatingStatus: 'Updating SautiLM-Jua-Agri from Hugging Face...',
    modelDownloadingStatus: 'Downloading SautiLM-Jua-Agri into private vault...',
    modelInstalledMsg: 'SautiLM-Jua-Agri installed and verified in private vault!',
    modelInterruptedMsg:
        'Download interrupted: please check your internet connection.',
    modelDeleteConfirmTitle: 'Delete local chat model?',
    modelDeleteConfirmBodyPrefix: 'This immediately frees',
    modelDeleteConfirmBodySuffix:
        'by removing SautiLM-Jua-Agri from private storage.\n\nSautiLM-Nuru-Agri leaf scanner (1.07 MB) and all 2,369 FAO/NARS records stay 100% offline.',
    modelFreeingSpaceMsg: 'Freeing local storage...',
    modelDeletedMsg: 'Chat model deleted. Storage space freed.',
    modelUpdateBtn: 'Update model',
    modelUpToDateBtn: 'Up to date',
    modelCheckUpdateBtn: 'Check update',
    modelDeleteBtn: 'Delete model',

    scanModalTitlePrefix: 'Crop Analysis ',
    scanBackgroundSnack:
        'AI scan running in background... Results will appear on Home.',
    scanProcessingMsg: 'SautiLM-Nuru-Agri is analyzing the leaf offline...',
    scanCanCloseHint: 'You can close this sheet and keep using the app.',
    scanResultHeader: 'Local Diagnosis & Remedy:',
    scanNotLeafTitle: 'Leaf not detected',
    scanNotLeafMessage:
        'The captured image does not look like a plant leaf. Please retake a clear photo focused on a crop leaf.',
    scanErrorTitle: 'Something went wrong',
    scanErrorMessage:
        'On-device AI analysis could not finish. Please retry with a well-lit photo.',
    scanRetakeBtn: 'Retake photo',
    scanRetryBtn: 'Close & Retry',

    historyTitle: 'Diagnostics History',
    historyEmptyTitle: 'No plant diagnostics yet',
    historyEmptyDesc:
        'Tap the camera icon to scan maize, cassava, banana, or bean leaves. Your diagnostics will appear here.',
    historyNewBadge: 'NEW',
    historyCropLabel: 'Crop',
    historyImpactTitle: 'Estimated Economic Impact & Yield Saved',
    historyImpactBody:
        'Untreated yield loss risk: ~40% to 70% per hectare.\nEstimated savings with FAO/IITA treatment: +\$120 to +\$350/ha.',
    historyRemediesTitle: 'Recommended corrective actions (FAO / IITA):',
    historyExportPdfBtn: 'Export PDF',
    historyDeleteDialogTitle: 'Delete?',
    historyDeleteDialogBodyPrefix:
        'Are you sure you want to delete this diagnostic from',
    historyDeleteDialogBodySuffix: 'This action cannot be undone.',
    historyDeletedSnack: 'Diagnostic deleted.',
    historyExportSingleTitlePrefix: 'Export Diagnostic PDF',
    historyExportSingleSubtitle:
        'Choose an option to save or share this diagnostic.',
    historySingleSavedPrefix: 'Diagnostic PDF saved in Documents',
    historyShareOrPrintTitle: 'Share or Print PDF',
    historyShareOrPrintSubtitle: 'Send via WhatsApp, Email or print directly',
    atTimeWord: 'at',
  );

  static const JuameaStringsData _sw = JuameaStringsData(
    language: JuameaLanguage.sw,
    selectLanguageTitle: 'Chagua Lugha',
    selectLanguageSubtitle:
        'Kiolesura na majibu ya AI ya Juamea hubadilika mara moja.',
    languageTooltip: 'Lugha (FR / EN / SW)',

    initSubtitle: 'Msaidizi wa kilimo wa AI 100% nje ya mtandao — Afrika Mashariki',
    initChecking: 'Inakagua rasilimali za akili bandia...',
    initConnectionStatusTitle: 'Hali ya mtandao',
    initErrorNetwork:
        'Muunganisho umekatika. Bonyeza Endelea kuendelea kupakua pale ulipoishia.',
    initErrorServer:
        'Seva za upakuaji zina shughuli nyingi sasa. Jaribu tena baada ya sekunde chache.',
    initErrorGeneric:
        'Hitilafu ndogo imetokea wakati wa usanidi. Bonyeza Endelea.',
    initCardTitle: 'SautiLM-Jua-Agri (Gumzo la AI)',
    initConnectingDesc:
        'Inaunganisha na Hugging Face. Faili (~283 MB) huhifadhiwa kwenye hifadhi ya siri ya Juamea na hufutwa ukiondoa programu.',
    initCheckingConnectionBtn: 'Inakagua...',
    initDownloadDesc:
        'Upakuaji wa hiari (~283 MB) kwenye hifadhi ya siri (hufutwa ukiondoa programu). Skani ya majani SautiLM-Nuru-Agri na rekodi 2,369 za FAO/NARS tayari zimo ndani.',
    initKeepOpenNotice:
        'Acha programu ikiwa wazi hadi upakuaji ukamilike.',
    initDownloadBtn: 'Pakua AI',
    initSkipBtn: 'Endelea bila AI',
    initPausedTitle: 'Usanidi umesimama',
    initPausedBadge: 'Imesimama',
    initPausedDesc:
        'Usanidi umekatishwa. Hakikisha una mtandao kisha bonyeza Endelea.',
    initResumeBtn: 'Endelea',
    okBtn: 'Sawa',

    navHome: 'Nyumbani',
    scanSheetTitle: 'Changanua jani',
    scanSheetSubtitle:
        'Chambua picha halisi ya zao lako nje ya mtandao kwa SautiLM-Nuru-Agri.',
    takePhotoTitle: 'Piga picha',
    takePhotoSubtitle: 'Piga picha ya jani moja kwa moja kwa kamera',
    choosePhotoTitle: 'Chagua picha',
    choosePhotoSubtitle: 'Chagua picha halisi kutoka kwenye ghala lako',
    imageOpenErrorPrefix: 'Imeshindwa kufungua picha',
    scanDoneSnack:
        'Uchambuzi umekamilika! Ripoti mpya inapatikana Nyumbani.',
    scanInterruptedPrefix: 'Uchambuzi umesimama',

    homeGreeting: 'Jambo! 👋🏾',
    homeSubtitle: 'Shamba lako la Afrika Mashariki, salama nje ya mtandao.',
    modelsTooltip: 'Injini za AI na Hifadhi',
    pdfTooltip: 'Hamisha Ripoti ya PDF',
    historyTooltip: 'Historia ya Uchunguzi',
    lastDiagnosticTitle: 'Uchunguzi wa Mwisho',
    noScanYet: 'Hakuna skani bado',
    tapScannerHint: 'Bonyeza skana',
    confidenceSuffix: 'uhakika',
    waterScheduleTitle: 'Ratiba ya Maji',
    rainPausedTitle: 'Mvua - Ratiba imesimama',
    irrigationActiveTitle: 'Umwagiliaji unaendelea',
    waterAllIrrigated: 'Mazao yote yamemwagiliwa',
    waterNextPrefix: 'Ijayo',
    waterOnDateWord: 'tarehe',
    waterRainPausedStatus: 'Mvua inatarajiwa - Umwagiliaji umesimama',
    soilRemindersTitle: 'Vikumbusho vya Udongo',
    reminderCassavaMosaic:
        'Kagua magugu na nzi weupe kwenye mashamba yako ya muhogo.',
    reminderMaizeRust:
        'Nyunyizia dawa ya asili ya mwarobaini (neem) kwenye mahindi.',
    reminderRainTomorrow:
        'Mvua inatarajiwa! Hifadhi mifuko ya mbolea mahali pakavu.',
    reminderDrySoil:
        'Tahadhari ya udongo mkavu. Fuatilia unyevu kwenye mahindi.',
    irrigationCalendarTitle: 'Kalenda ya Umwagiliaji',
    autonomousAdjustLabel: 'Marekebisho otomatiki',
    dateLabel: 'Tarehe: ',
    rainSwitchLabel: 'Mvua ',
    retryBtn: 'Jaribu tena',

    pdfSheetTitle: 'Ripoti ya Uzalishaji (PDF)',
    pdfSheetSubtitle:
        'Chagua jinsi ya kuhamisha ripoti yako ya kilimo.',
    pdfSavedSnackPrefix: 'Ripoti ya PDF imehifadhiwa kwenye Nyaraka',
    pdfOpenBtn: 'Fungua',
    pdfDownloadTitle: 'Pakua PDF',
    pdfDownloadSubtitle: 'Hifadhi kwenye folda ya Documents ya simu',
    pdfShareTitle: 'Shiriki PDF',
    pdfShareSubtitle: 'Tuma kupitia WhatsApp, Barua pepe, Drive au Bluetooth',
    pdfDownloadErrorPrefix: 'Hitilafu ya upakuaji',
    pdfShareErrorPrefix: 'Hitilafu ya kushiriki',

    chatWelcome:
        'Jambo 👋🏾! Mimi ni Juamea, msaidizi wako wa kilimo wa AI 100% nje ya mtandao kwa Afrika Mashariki. Niulize kuhusu muhogo, mahindi, dawa za asili za mwarobaini au mvua ili kurekebisha ratiba ya umwagiliaji!',
    chatMissingModelPrompt:
        'Modeli ya AI SautiLM-Jua-Agri bado haijapakuliwa kwenye kifaa hiki. Bonyeza « Pakua modeli » ili kuwezesha gumzo nje ya mtandao.',
    chatMissingBannerText: 'Modeli ya AI inahitajika kwa gumzo nje ya mtandao.',
    chatDownloadBtnShort: 'Pakua',
    chatDownloadBtnFull: 'Pakua modeli',
    chatModelTooltip: 'Modeli ya AI',
    chatClearTooltip: 'Futa mazungumzo',
    chatClearTitle: 'Kufuta mazungumzo?',
    chatClearBody:
        'Una uhakika unataka kufuta ujumbe wote? Hatua hii haiwezi kutenduliwa.',
    cancelBtn: 'Ghairi',
    deleteBtn: 'Futa',
    faoBadgeLabel: 'Msingi wa FAO RAG',
    stopLabel: 'SIMAMA',
    listenLabel: 'Sikiliza',
    micListeningTooltip: 'Inasikiliza...',
    micVoiceTooltip: 'Ingiza kwa sauti',
    chatInputHint: 'Uliza kuhusu mazao, wadudu au mvua...',
    chatRainAdjustedNotice:
        'Kalenda imerekebishwa: Umwagiliaji umesimamishwa kutokana na mvua.',
    chatDryAdjustedNotice:
        'Kalenda imerekebishwa: Umwagiliaji wa kawaida umerejeshwa kwa hali ya ukame.',
    chatBusyPlaceholder:
        'Nitakujibu mara tu uchambuzi wa jani utakapokamilika...',
    chatEmptyFallback: 'Siwezi kujibu kwa sasa, tafadhali jaribu tena.',
    chatErrorFallback:
        'Siwezi kujibu kwa sasa. Tafadhali jaribu tena au kagua modeli ya AI.',

    modelModalTitle: 'Injini za AI na Hifadhi ya Siri',
    modelModalStoreNote:
        'Kiwango cha Play Store & App Store: hakuna ruhusa ya faili za nje. Faili zote zilizopakuliwa hufutwa kiotomatiki ukiondoa Juamea.',
    modelNuruTitle: 'SautiLM-Nuru-Agri (1.07 MB) + SQLite FAO/NARS',
    modelNuruDesc:
        'Imo ndani ya programu: skana ya majani ya madaraja 9 + rekodi 2,369 za kilimo cha Afrika Mashariki nje ya mtandao.',
    modelJuaTitle: 'SautiLM-Jua-Agri (Gumzo la AI)',
    modelNotInstalledBadge: 'Haijasakinishwa',
    modelVaultPrefix: 'Hifadhi ya siri salama',
    modelOptionalDesc:
        'Modeli ya hiari (~283 MB) kwa mazungumzo ya kina ya kilimo nje ya mtandao.',
    modelCheckShaNotice: 'Inakagua SHA-256 ya Hugging Face (< 2 KB)...',
    modelUpToDateMsg: 'SautiLM-Jua-Agri tayari imesasishwa',
    modelUpdateAvailableMsg: 'Toleo jipya linapatikana kwenye Hugging Face',
    modelNotInstalledMsg: 'Modeli ya gumzo bado haijapakuliwa',
    modelOfflineCheckMsg:
        'Nje ya mtandao: unganisha mtandao kwa muda mfupi kukagua sasisho.',
    modelCheckErrorPrefix: 'Hitilafu ya ukaguzi',
    modelUpdatingStatus: 'Inasasisha SautiLM-Jua-Agri kutoka Hugging Face...',
    modelDownloadingStatus:
        'Inapakua SautiLM-Jua-Agri kwenye hifadhi ya siri...',
    modelInstalledMsg:
        'SautiLM-Jua-Agri imesakinishwa na kuthibitishwa!',
    modelInterruptedMsg:
        'Upakuaji umekatika: kagua muunganisho wako wa intaneti.',
    modelDeleteConfirmTitle: 'Kufuta modeli ya gumzo?',
    modelDeleteConfirmBodyPrefix: 'Hatua hii itarejesha',
    modelDeleteConfirmBodySuffix:
        'kwa kufuta SautiLM-Jua-Agri kwenye hifadhi ya siri.\n\nSkana ya majani SautiLM-Nuru-Agri (1.07 MB) na rekodi 2,369 za FAO/NARS zitaendelea kufanya kazi 100% nje ya mtandao.',
    modelFreeingSpaceMsg: 'Inarejesha nafasi ya hifadhi...',
    modelDeletedMsg: 'Modeli imefutwa. Nafasi ya hifadhi imerejeshwa.',
    modelUpdateBtn: 'Sasisha modeli',
    modelUpToDateBtn: 'Imesasishwa',
    modelCheckUpdateBtn: 'Kagua sasisho',
    modelDeleteBtn: 'Futa modeli',

    scanModalTitlePrefix: 'Uchambuzi wa Zao ',
    scanBackgroundSnack:
        'Uchambuzi wa AI unaendelea chinichini... Matokeo yataonekana Nyumbani.',
    scanProcessingMsg: 'SautiLM-Nuru-Agri inachambua jani nje ya mtandao...',
    scanCanCloseHint: 'Unaweza kufunga dirisha hili na kuendelea kutumia programu.',
    scanResultHeader: 'Uchunguzi na Tiba ya Asili:',
    scanNotLeafTitle: 'Jani halijatambuliwa',
    scanNotLeafMessage:
        'Picha iliyopigwa haionekani kuwa jani la mmea. Tafadhali piga picha nyingine ikilenga wazi jani la zao lako.',
    scanErrorTitle: 'Hitilafu imetokea',
    scanErrorMessage:
        'Uchambuzi wa AI haukuweza kukamilika. Jaribu tena kwa picha yenye mwanga mzuri.',
    scanRetakeBtn: 'Piga picha tena',
    scanRetryBtn: 'Funga & Jaribu tena',

    historyTitle: 'Historia ya Uchunguzi',
    historyEmptyTitle: 'Hakuna uchunguzi bado',
    historyEmptyDesc:
        'Tumia kitufe cha kamera kuchanganua majani ya mahindi, muhogo, ndizi au maharage. Ripoti zako zitaonekana hapa.',
    historyNewBadge: 'MPYA',
    historyCropLabel: 'Zao',
    historyImpactTitle: 'Makadirio ya Athari za Kiuchumi',
    historyImpactBody:
        'Hatari ya hasara bila tiba: ~40% hadi 70% ya mavuno kwa hekta.\nFaida inayokadiriwa kwa tiba ya FAO: +\$120 hadi +\$350/ha.',
    historyRemediesTitle: 'Hatua za tiba zinazopendekezwa (FAO / IITA):',
    historyExportPdfBtn: 'Hamisha PDF',
    historyDeleteDialogTitle: 'Kufuta?',
    historyDeleteDialogBodyPrefix:
        'Una uhakika unataka kufuta uchunguzi huu wa',
    historyDeleteDialogBodySuffix: 'Hatua hii haiwezi kutenduliwa.',
    historyDeletedSnack: 'Uchunguzi umefutwa.',
    historyExportSingleTitlePrefix: 'Hamisha PDF ya Uchunguzi',
    historyExportSingleSubtitle:
        'Chagua chaguo la kuhifadhi au kushiriki uchunguzi huu.',
    historySingleSavedPrefix: 'PDF ya uchunguzi imehifadhiwa kwenye Nyaraka',
    historyShareOrPrintTitle: 'Shiriki au Chapisha PDF',
    historyShareOrPrintSubtitle: 'Tuma kupitia WhatsApp, Barua pepe au chapisha',
    atTimeWord: 'saa',
  );
}

class JuameaStringsData {
  final JuameaLanguage language;
  final String selectLanguageTitle;
  final String selectLanguageSubtitle;
  final String languageTooltip;

  final String initSubtitle;
  final String initChecking;
  final String initConnectionStatusTitle;
  final String initErrorNetwork;
  final String initErrorServer;
  final String initErrorGeneric;
  final String initCardTitle;
  final String initConnectingDesc;
  final String initCheckingConnectionBtn;
  final String initDownloadDesc;
  final String initKeepOpenNotice;
  final String initDownloadBtn;
  final String initSkipBtn;
  final String initPausedTitle;
  final String initPausedBadge;
  final String initPausedDesc;
  final String initResumeBtn;
  final String okBtn;

  final String navHome;
  final String scanSheetTitle;
  final String scanSheetSubtitle;
  final String takePhotoTitle;
  final String takePhotoSubtitle;
  final String choosePhotoTitle;
  final String choosePhotoSubtitle;
  final String imageOpenErrorPrefix;
  final String scanDoneSnack;
  final String scanInterruptedPrefix;

  final String homeGreeting;
  final String homeSubtitle;
  final String modelsTooltip;
  final String pdfTooltip;
  final String historyTooltip;
  final String lastDiagnosticTitle;
  final String noScanYet;
  final String tapScannerHint;
  final String confidenceSuffix;
  final String waterScheduleTitle;
  final String rainPausedTitle;
  final String irrigationActiveTitle;
  final String waterAllIrrigated;
  final String waterNextPrefix;
  final String waterOnDateWord;
  final String waterRainPausedStatus;
  final String soilRemindersTitle;
  final String reminderCassavaMosaic;
  final String reminderMaizeRust;
  final String reminderRainTomorrow;
  final String reminderDrySoil;
  final String irrigationCalendarTitle;
  final String autonomousAdjustLabel;
  final String dateLabel;
  final String rainSwitchLabel;
  final String retryBtn;

  final String pdfSheetTitle;
  final String pdfSheetSubtitle;
  final String pdfSavedSnackPrefix;
  final String pdfOpenBtn;
  final String pdfDownloadTitle;
  final String pdfDownloadSubtitle;
  final String pdfShareTitle;
  final String pdfShareSubtitle;
  final String pdfDownloadErrorPrefix;
  final String pdfShareErrorPrefix;

  final String chatWelcome;
  final String chatMissingModelPrompt;
  final String chatMissingBannerText;
  final String chatDownloadBtnShort;
  final String chatDownloadBtnFull;
  final String chatModelTooltip;
  final String chatClearTooltip;
  final String chatClearTitle;
  final String chatClearBody;
  final String cancelBtn;
  final String deleteBtn;
  final String faoBadgeLabel;
  final String stopLabel;
  final String listenLabel;
  final String micListeningTooltip;
  final String micVoiceTooltip;
  final String chatInputHint;
  final String chatRainAdjustedNotice;
  final String chatDryAdjustedNotice;
  final String chatBusyPlaceholder;
  final String chatEmptyFallback;
  final String chatErrorFallback;

  final String modelModalTitle;
  final String modelModalStoreNote;
  final String modelNuruTitle;
  final String modelNuruDesc;
  final String modelJuaTitle;
  final String modelNotInstalledBadge;
  final String modelVaultPrefix;
  final String modelOptionalDesc;
  final String modelCheckShaNotice;
  final String modelUpToDateMsg;
  final String modelUpdateAvailableMsg;
  final String modelNotInstalledMsg;
  final String modelOfflineCheckMsg;
  final String modelCheckErrorPrefix;
  final String modelUpdatingStatus;
  final String modelDownloadingStatus;
  final String modelInstalledMsg;
  final String modelInterruptedMsg;
  final String modelDeleteConfirmTitle;
  final String modelDeleteConfirmBodyPrefix;
  final String modelDeleteConfirmBodySuffix;
  final String modelFreeingSpaceMsg;
  final String modelDeletedMsg;
  final String modelUpdateBtn;
  final String modelUpToDateBtn;
  final String modelCheckUpdateBtn;
  final String modelDeleteBtn;

  final String scanModalTitlePrefix;
  final String scanBackgroundSnack;
  final String scanProcessingMsg;
  final String scanCanCloseHint;
  final String scanResultHeader;
  final String scanNotLeafTitle;
  final String scanNotLeafMessage;
  final String scanErrorTitle;
  final String scanErrorMessage;
  final String scanRetakeBtn;
  final String scanRetryBtn;

  final String historyTitle;
  final String historyEmptyTitle;
  final String historyEmptyDesc;
  final String historyNewBadge;
  final String historyCropLabel;
  final String historyImpactTitle;
  final String historyImpactBody;
  final String historyRemediesTitle;
  final String historyExportPdfBtn;
  final String historyDeleteDialogTitle;
  final String historyDeleteDialogBodyPrefix;
  final String historyDeleteDialogBodySuffix;
  final String historyDeletedSnack;
  final String historyExportSingleTitlePrefix;
  final String historyExportSingleSubtitle;
  final String historySingleSavedPrefix;
  final String historyShareOrPrintTitle;
  final String historyShareOrPrintSubtitle;
  final String atTimeWord;

  const JuameaStringsData({
    required this.language,
    required this.selectLanguageTitle,
    required this.selectLanguageSubtitle,
    required this.languageTooltip,
    required this.initSubtitle,
    required this.initChecking,
    required this.initConnectionStatusTitle,
    required this.initErrorNetwork,
    required this.initErrorServer,
    required this.initErrorGeneric,
    required this.initCardTitle,
    required this.initConnectingDesc,
    required this.initCheckingConnectionBtn,
    required this.initDownloadDesc,
    required this.initKeepOpenNotice,
    required this.initDownloadBtn,
    required this.initSkipBtn,
    required this.initPausedTitle,
    required this.initPausedBadge,
    required this.initPausedDesc,
    required this.initResumeBtn,
    required this.okBtn,
    required this.navHome,
    required this.scanSheetTitle,
    required this.scanSheetSubtitle,
    required this.takePhotoTitle,
    required this.takePhotoSubtitle,
    required this.choosePhotoTitle,
    required this.choosePhotoSubtitle,
    required this.imageOpenErrorPrefix,
    required this.scanDoneSnack,
    required this.scanInterruptedPrefix,
    required this.homeGreeting,
    required this.homeSubtitle,
    required this.modelsTooltip,
    required this.pdfTooltip,
    required this.historyTooltip,
    required this.lastDiagnosticTitle,
    required this.noScanYet,
    required this.tapScannerHint,
    required this.confidenceSuffix,
    required this.waterScheduleTitle,
    required this.rainPausedTitle,
    required this.irrigationActiveTitle,
    required this.waterAllIrrigated,
    required this.waterNextPrefix,
    required this.waterOnDateWord,
    required this.waterRainPausedStatus,
    required this.soilRemindersTitle,
    required this.reminderCassavaMosaic,
    required this.reminderMaizeRust,
    required this.reminderRainTomorrow,
    required this.reminderDrySoil,
    required this.irrigationCalendarTitle,
    required this.autonomousAdjustLabel,
    required this.dateLabel,
    required this.rainSwitchLabel,
    required this.retryBtn,
    required this.pdfSheetTitle,
    required this.pdfSheetSubtitle,
    required this.pdfSavedSnackPrefix,
    required this.pdfOpenBtn,
    required this.pdfDownloadTitle,
    required this.pdfDownloadSubtitle,
    required this.pdfShareTitle,
    required this.pdfShareSubtitle,
    required this.pdfDownloadErrorPrefix,
    required this.pdfShareErrorPrefix,
    required this.chatWelcome,
    required this.chatMissingModelPrompt,
    required this.chatMissingBannerText,
    required this.chatDownloadBtnShort,
    required this.chatDownloadBtnFull,
    required this.chatModelTooltip,
    required this.chatClearTooltip,
    required this.chatClearTitle,
    required this.chatClearBody,
    required this.cancelBtn,
    required this.deleteBtn,
    required this.faoBadgeLabel,
    required this.stopLabel,
    required this.listenLabel,
    required this.micListeningTooltip,
    required this.micVoiceTooltip,
    required this.chatInputHint,
    required this.chatRainAdjustedNotice,
    required this.chatDryAdjustedNotice,
    required this.chatBusyPlaceholder,
    required this.chatEmptyFallback,
    required this.chatErrorFallback,
    required this.modelModalTitle,
    required this.modelModalStoreNote,
    required this.modelNuruTitle,
    required this.modelNuruDesc,
    required this.modelJuaTitle,
    required this.modelNotInstalledBadge,
    required this.modelVaultPrefix,
    required this.modelOptionalDesc,
    required this.modelCheckShaNotice,
    required this.modelUpToDateMsg,
    required this.modelUpdateAvailableMsg,
    required this.modelNotInstalledMsg,
    required this.modelOfflineCheckMsg,
    required this.modelCheckErrorPrefix,
    required this.modelUpdatingStatus,
    required this.modelDownloadingStatus,
    required this.modelInstalledMsg,
    required this.modelInterruptedMsg,
    required this.modelDeleteConfirmTitle,
    required this.modelDeleteConfirmBodyPrefix,
    required this.modelDeleteConfirmBodySuffix,
    required this.modelFreeingSpaceMsg,
    required this.modelDeletedMsg,
    required this.modelUpdateBtn,
    required this.modelUpToDateBtn,
    required this.modelCheckUpdateBtn,
    required this.modelDeleteBtn,
    required this.scanModalTitlePrefix,
    required this.scanBackgroundSnack,
    required this.scanProcessingMsg,
    required this.scanCanCloseHint,
    required this.scanResultHeader,
    required this.scanNotLeafTitle,
    required this.scanNotLeafMessage,
    required this.scanErrorTitle,
    required this.scanErrorMessage,
    required this.scanRetakeBtn,
    required this.scanRetryBtn,
    required this.historyTitle,
    required this.historyEmptyTitle,
    required this.historyEmptyDesc,
    required this.historyNewBadge,
    required this.historyCropLabel,
    required this.historyImpactTitle,
    required this.historyImpactBody,
    required this.historyRemediesTitle,
    required this.historyExportPdfBtn,
    required this.historyDeleteDialogTitle,
    required this.historyDeleteDialogBodyPrefix,
    required this.historyDeleteDialogBodySuffix,
    required this.historyDeletedSnack,
    required this.historyExportSingleTitlePrefix,
    required this.historyExportSingleSubtitle,
    required this.historySingleSavedPrefix,
    required this.historyShareOrPrintTitle,
    required this.historyShareOrPrintSubtitle,
    required this.atTimeWord,
  });
}
