import 'package:intl/intl.dart';

import '../../data/models/reimbursement_claim.dart';
import '../../data/models/attendance_record.dart';
import '../../data/models/izin_record.dart';

class AppStrings {
  AppStrings._();

  static const String appTitle = 'KZB';
  static const String brandName = 'CV Kazim Berkah';
  static const String splashCompanyName = 'CV KAZIM BERKAH';
  static const String splashTagline = 'Human Resource Information System';
  static const String homeTitle = 'Beranda';
  static const String attendanceTitle = 'Absen';
  static const String calendarTitle = 'Riwayat Absen';
  static const String reimbursementTitle = 'Reimbursement';
  static const String newClaimTitle = 'Reimbursement';
  static const String izinTitle = 'Izin';
  static const String newIzinTitle = 'Buat Izin';
  static const String documentsTitle = 'Aktivitas';
  static const String moreTitle = 'Pengaturan';
  static const String settingsTitle = 'Pengaturan';
  static const String profileLabel = 'Profile';
  static const String roleLabel = 'Jabatan';
  static const String aboutTitle = 'Tentang Aplikasi';
  static const String aboutVersionLabel = 'Versi 1.0.0';
  static const String notAvailableMessage = 'Fitur ini belum tersedia';

  static const String changePhotoLabel = 'Ubah Foto';
  static const String nameField = 'Nama';
  static const String profileSectionTitle = 'Profile';
  static const String saveButton = 'SAVE';
  static const String settingsSavedMessage = 'Pengaturan berhasil disimpan';
  static const String profilePictureUpdatedMessage = 'Foto profil diperbarui';
  static const String profilePictureSaveError =
      'Gagal menyimpan foto profil. Silakan coba lagi.';
  static const String invalidName = 'Masukkan nama';
  static const String changePasswordTitle = 'Ubah Password';
  static const String newPasswordField = 'Password Baru';
  static const String newPasswordHint = 'Masukkan password baru';
  static const String confirmNewPasswordField = 'Konfirmasi Password Baru';
  static const String confirmNewPasswordHint = 'Ulangi password baru';
  static const String invalidConfirmPassword =
      'Konfirmasi password tidak cocok';
  static const String currentPasswordField = 'Password Saat Ini';
  static const String currentPasswordHint = 'Masukkan password saat ini';
  static const String requiredCurrentPassword = 'Masukkan password saat ini';
  static const String invalidCurrentPassword = 'Password saat ini salah';
  static const String passwordChangedMessage = 'Password berhasil diubah';
  static const String dateOfBirthField = 'Tanggal Lahir';
  static const String dateOfBirthHint = 'Pilih tanggal lahir';
  static const String invalidDateOfBirth = 'Pilih tanggal lahir';
  static const String invalidPasswordLength = 'Kata sandi minimal 6 karakter';
  static const String locationPermissionDenied =
      'Izin lokasi diperlukan untuk melakukan absen';
  static const String poorConnectionMessage =
      'Koneksi anda buruk, mohon dicoba absen kembali';
  static const String selfieSaveError =
      'Gagal menyimpan foto selfie. Silakan coba lagi.';
  static const String photoSourceTitle = 'Sumber Foto';
  static const String cameraActionLabel = 'Ambil Foto';
  static const String galleryActionLabel = 'Pilih dari Galeri';

  static const String loginTitle = 'Masuk';
  static const String loginWelcome = 'Selamat Datang';
  static const String loginSubtitle =
      'Masuk menggunakan akun yang diberikan oleh admin';
  static const String loginUsernameField = 'Username';
  static const String loginUsernameHint = 'Masukkan username';
  static const String loginPasswordField = 'Kata Sandi';
  static const String loginPasswordHint = 'Masukkan kata sandi';
  static const String loginButton = 'MASUK';
  static const String loginProgressLabel = 'MEMVERIFIKASI';
  static const String invalidUsername = 'Masukkan username atau email';
  static const String invalidPassword = 'Masukkan kata sandi';
  static const String invalidCredentials = 'Username atau kata sandi salah';
  static const String loginFailedMessage = 'Gagal masuk. Silakan coba lagi.';
  static const String logoutLabel = 'Keluar';
  static const String logoutConfirmTitle = 'Keluar dari Aplikasi';
  static const String logoutConfirmMessage =
      'Anda akan kembali ke halaman masuk.';
  static const String logoutActionLabel = 'KELUAR';
  static const String cancelActionLabel = 'BATAL';
  static const String okActionLabel = 'OK';

  static const String settingsLoadError =
      'Gagal memuat pengaturan. Silakan coba lagi.';
  static const String settingsSaveError =
      'Gagal menyimpan pengaturan. Silakan coba lagi.';

  static const String navHome = 'Beranda';
  static const String navDocuments = 'Aktivitas';
  static const String navMore = 'Pengaturan';

  static const String greetingMorning = 'Selamat Pagi';
  static const String greetingAfternoon = 'Selamat Siang';
  static const String greetingEvening = 'Selamat Sore';
  static const String greetingNight = 'Selamat Malam';
  static const String greetingSubtitle = 'Tolong jaga kesehatan yaa. Semangat';

  static const String checkInCard = 'Absen Masuk';
  static const String checkOutCard = 'Absen Keluar';
  static const String startVisitCard = 'Mulai Kunjungan';
  static const String endVisitCard = 'Selesai Kunjungan';
  static const String reimbursementCard = 'Reimbursement';
  static const String timesheetCard = 'Timesheet';

  static const String startVisitTitle = 'Mulai Kunjungan';
  static const String endVisitTitle = 'Selesai Kunjungan';
  static const String kunjunganNowTimeField = 'Waktu sekarang';
  static const String kunjunganEndTimeField = 'Waktu selesai';
  static const String clientNameField = 'Nama klien';
  static const String clientNameHint = 'Masukkan nama klien';
  static const String visitNotesField = 'Tambahkan keterangan';
  static const String visitNotesHint = 'Tambahkan keterangan kunjungan';
  static const String endVisitNotesField = 'Hasil kunjungan';
  static const String endVisitNotesHint = 'Tuliskan hasil kunjungan';
  static const String evidenceLabel = 'Bukti';
  static const String gpsLocationLabel = 'Lokasi GPS';
  static const String currentAddressLabel = 'Alamat saat ini';
  static const String locatingLabel = 'Mencari lokasi...';
  static const String savingMessage = 'Menyimpan...';
  static const String submitStartVisitButton = 'Mulai Kunjungan';
  static const String submitEndVisitButton = 'Kirim Kunjungan';
  static const String visitSavedMessage = 'Kunjungan berhasil dicatat';
  static const String visitFailedMessage =
      'Gagal menyimpan kunjungan. Silakan coba lagi.';
  static const String invalidClientName = 'Masukkan nama klien';

  static const String timesheetTitle = 'Timesheet';
  static const String noTasksTitle = 'Belum ada tugas untuk hari ini';
  static const String noTasksBody =
      'Tugas akan muncul setelah Admin membagikannya di sini';
  static const String taskDetailTitle = 'Detail Tugas';
  static const String taskInstructionsLabel = 'Instruksi Tugas';
  static const String taskProofLabel = 'Bukti Pengerjaan';
  static const String taskProofHint = 'Ketuk untuk memilih foto bukti';
  static const String taskCompletedLabel = 'Selesai';
  static const String taskPendingLabel = 'Belum Selesai';
  static const String submitProofButton = 'Kirim Bukti';
  static const String proofPickError = 'Pilih foto bukti terlebih dahulu';
  static const String proofSubmitError =
      'Gagal mengirim bukti. Silakan coba lagi.';
  static const String proofSubmittedMessage = 'Bukti berhasil dikirim';

  static const String kunjunganHistoryTitle = 'Riwayat Kunjungan';
  static const String kunjunganHistorySubtitle = 'Mulai & selesai kunjungan';
  static const String emptyKunjungans = 'Belum ada riwayat kunjungan';

  static const String reimbActivityField = 'Nama kegiatan';
  static const String reimbActivityHint = 'Masukkan nama kegiatan';
  static const String reimbCategoryField = 'Kategori';
  static const String reimbDateField = 'Tanggal';
  static const String reimbCurrencyField = 'Mata uang';
  static const String reimbAmountField = 'Jumlah';
  static const String reimbAmountHint = 'Masukkan jumlah';
  static const String reimbSellerField = 'Nama penjual';
  static const String reimbSellerHint = 'Masukkan nama penjual';
  static const String reimbNotesField = 'Keterangan';
  static const String reimbNotesHint = 'Tambahkan keterangan';
  static const String reimbEvidenceLabel = 'Bukti';
  static const String reimbEvidenceHint = 'Ketuk untuk memilih foto bukti';
  static const String submitProcessButton = 'PROSES';
  static const String invalidActivity = 'Masukkan nama kegiatan';
  static const String invalidSeller = 'Masukkan nama penjual';
  static const String idr = 'IDR';
  static const String usd = 'USD';

  static const String projectLabel = 'Proyek Aktif';
  static const String attendanceSummaryTitle = 'Ringkasan Bulan Ini';
  static const String attendanceSectionLabel = 'Status Kehadiran Hari Ini';
  static const String reimbursementSummaryTitle = 'Reimburse';
  static const String presentLabel = 'Hadir';
  static const String pendingLabel = 'Menunggu';
  static const String approvedLabel = 'Disetujui';
  static const String rejectedLabel = 'Ditolak';
  static const String totalPendingAmountLabel = 'Total Menunggu';
  static const String clockedInBadge = 'Sudah absen hari ini';
  static const String notClockedInBadge = 'Belum absen hari ini';
  static const String checkOutWaitingLabel =
      'Absen Keluar dapat dilakukan 3 jam setelah Absen Masuk';
  static const String cycleDoneLabel =
      'Kamu sudah absen hari ini (Masuk & Keluar)';
  static const String dashboardCycleDoneLabel = 'Kamu sudah absen hari ini';
  static const String alreadyClockedTodayMessage = 'Kamu sudah Absen hari ini';
  static const String attendanceRecordedLabel = 'Selesai';

  static const String clockActionLabel = 'Absen';
  static const String clockActionSubtitle = 'Geotag & selfie';
  static const String reimbursementActionLabel = 'Reimburse';
  static const String reimbursementActionSubtitle = 'Petty cash';
  static const String historyActionLabel = 'Riwayat Absen';
  static const String historyActionSubtitle = 'Kalender kehadiran';
  static const String izinActionLabel = 'Izin';
  static const String izinActionSubtitle = 'Cuti / sakit';

  static const String errorRetry = 'Muat Ulang';
  static const String serverTimeLabel = 'Waktu Server';
  static const String addressLabel = 'Alamat';
  static const String coordinatesLabel = 'Koordinat';
  static const String checkInLabel = 'Masuk';
  static const String checkOutLabel = 'Keluar';
  static const String checkInAction = 'Absen Masuk';
  static const String checkOutAction = 'Absen Keluar';
  static const String gpsChipLabel = 'Lokasi GPS';
  static const String selfiePrompt =
      'Ketuk tombol Absen untuk mengambil selfie';
  static const String selfieCapturedLabel = 'Selfie terambil';
  static const String locationNotObtained = 'Lokasi belum diambil';
  static const String noPhotoLabel = 'Tidak ada foto';
  static const String noRecordsForDay = 'Tidak ada catatan untuk tanggal ini';
  static const String dayDetailTitle = 'Detail Kehadiran';
  static const String legendTitle = 'Keterangan';

  static const String filterAll = 'Semua';
  static const String emptyClaims = 'Belum ada pengajuan reimburse';
  static const String emptyIzins = 'Belum ada pengajuan izin';
  static const String newClaimAction = 'Ajukan';
  static const String hasAttachment = 'Lampiran';

  static const String amountField = 'Jumlah (Rp)';
  static const String amountHint = 'Contoh: 150000';
  static const String categoryField = 'Kategori Pengeluaran';
  static const String notesField = 'Catatan';
  static const String notesHint = 'Contoh: Bensin untuk perjalanan ke gudang';
  static const String uploadReceiptTitle = 'Lampiran Bukti';
  static const String uploadReceiptHint = 'Ketuk untuk memilih foto bukti';
  static const String submitClaimButton = 'Kirim Pengajuan';
  static const String claimSavedMessage = 'Pengajuan berhasil dikirim';

  static const String izinDateField = 'Tanggal';
  static const String izinDateHint = 'Pilih tanggal izin';
  static const String izinReasonField = 'Alasan';
  static const String selectReasonHint = 'Pilih alasan izin';
  static const String izinNotesHint = 'Contoh: Surat keterangan dokter';
  static const String izinPhotoTitle = 'Lampiran Foto';
  static const String izinPhotoHint = 'Ketuk untuk memilih foto';
  static const String izinSubmitButton = 'Kirim Izin';
  static const String izinSavedMessage = 'Pengajuan izin berhasil dikirim';

  static const String invalidAmount = 'Masukkan jumlah pengeluaran';
  static const String invalidCategory = 'Pilih kategori pengeluaran';
  static const String selectCategoryHint = 'Pilih kategori pengeluaran';
  static const String invalidDate = 'Pilih tanggal izin';
  static const String invalidReason = 'Pilih alasan izin';

  static const String submittedLabel = 'Diajukan';

  static const List<String> _monthNames = [
    'Januari',
    'Februari',
    'Maret',
    'April',
    'Mei',
    'Juni',
    'Juli',
    'Agustus',
    'September',
    'Oktober',
    'November',
    'Desember',
  ];

  static const List<String> _dayNames = [
    'Senin',
    'Selasa',
    'Rabu',
    'Kamis',
    'Jumat',
    'Sabtu',
    'Minggu',
  ];

  static String fullDate(DateTime date) {
    final dayName = _dayNames[date.weekday - 1];
    return '$dayName, ${date.day} ${_monthNames[date.month - 1]} ${date.year}';
  }

  static String monthYearLabel(DateTime date) =>
      '${_monthNames[date.month - 1]} ${date.year}';

  static String formatCurrency(double amount) {
    return 'Rp ${NumberFormat.decimalPattern('id').format(amount.round())}';
  }

  static String greetingForTime(DateTime time) {
    final minutes = time.hour * 60 + time.minute;
    if (minutes < 12 * 60) {
      return greetingMorning;
    }
    if (minutes < 15 * 60) {
      return greetingAfternoon;
    }
    if (minutes < 18 * 60 + 30) {
      return greetingEvening;
    }
    return greetingNight;
  }

  static String homeGreeting(String name, DateTime time) {
    final firstName = name
        .trim()
        .split(RegExp(r'\s+'))
        .firstWhere((part) => part.isNotEmpty, orElse: () => '');
    final greeting = greetingForTime(time);
    return firstName.isEmpty ? greeting : '$greeting $firstName';
  }

  static String shortDate(DateTime date) {
    return DateFormat('d MMM yyyy').format(date);
  }

  static String timeLabel(DateTime time) {
    return DateFormat('HH:mm').format(time);
  }

  static String fileNameFromPath(String path) {
    final normalized = path.replaceAll('\\', '/');
    final segments = normalized.split('/');
    return segments.isEmpty ? path : segments.last;
  }

  static String eventTypeLabel(ClockEventType type) => switch (type) {
    ClockEventType.checkIn => checkInLabel,
    ClockEventType.checkOut => checkOutLabel,
  };

  static String attendanceActionLabel(ClockEventType type) => switch (type) {
    ClockEventType.checkIn => checkInAction,
    ClockEventType.checkOut => checkOutAction,
  };

  static String claimStatusLabel(ClaimStatus status) => switch (status) {
    ClaimStatus.pending => pendingLabel,
    ClaimStatus.approved => approvedLabel,
    ClaimStatus.rejected => rejectedLabel,
  };

  static String izinStatusLabel(IzinStatus status) => switch (status) {
    IzinStatus.pending => pendingLabel,
    IzinStatus.approved => approvedLabel,
    IzinStatus.rejected => rejectedLabel,
  };

  static String expenseCategoryLabel(ExpenseCategory category) =>
      switch (category) {
        ExpenseCategory.material => 'Material',
        ExpenseCategory.transport => 'Transport',
        ExpenseCategory.meals => 'Makanan',
        ExpenseCategory.other => 'Lainnya',
      };

  static String izinReasonLabel(IzinReason reason) => switch (reason) {
    IzinReason.sick => 'Sakit',
    IzinReason.family => 'Keperluan Keluarga',
    IzinReason.other => 'Lainnya',
  };
}
