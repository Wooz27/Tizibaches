enum PotholeStatus {
  pending,
  reported,
  verified,
  scheduled,
  inProgress,
  fixed,
  rejected,
  unknown;

  static PotholeStatus fromApi(String? value) {
    return switch (value) {
      'pending' => PotholeStatus.pending,
      'reported' => PotholeStatus.reported,
      'verified' => PotholeStatus.verified,
      'scheduled' => PotholeStatus.scheduled,
      'in_progress' => PotholeStatus.inProgress,
      'fixed' => PotholeStatus.fixed,
      'rejected' => PotholeStatus.rejected,
      _ => PotholeStatus.unknown,
    };
  }

  String get apiValue => switch (this) {
    PotholeStatus.pending => 'pending',
    PotholeStatus.reported => 'reported',
    PotholeStatus.verified => 'verified',
    PotholeStatus.scheduled => 'scheduled',
    PotholeStatus.inProgress => 'in_progress',
    PotholeStatus.fixed => 'fixed',
    PotholeStatus.rejected => 'rejected',
    PotholeStatus.unknown => 'unknown',
  };

  String get label => switch (this) {
    PotholeStatus.pending => 'Pendiente de revisión',
    PotholeStatus.reported => 'Reportado',
    PotholeStatus.verified => 'Verificado',
    PotholeStatus.scheduled => 'Programado',
    PotholeStatus.inProgress => 'En obra',
    PotholeStatus.fixed => 'Reparado',
    PotholeStatus.rejected => 'Rechazado',
    PotholeStatus.unknown => 'Sin estado',
  };
}
