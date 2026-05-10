class PendingAction {
  final int? id;
  final String endpoint;
  final String method;
  final String payload;
  final String mobileRef;
  final String status;

  PendingAction({
    this.id,
    required this.endpoint,
    required this.method,
    required this.payload,
    required this.mobileRef,
    this.status = 'pending',
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'endpoint': endpoint,
      'method': method,
      'payload': payload,
      'mobile_ref': mobileRef,
      'status': status,
    };
  }

  factory PendingAction.fromMap(Map<String, dynamic> map) {
    return PendingAction(
      id: map['id'],
      endpoint: map['endpoint'],
      method: map['method'],
      payload: map['payload'],
      mobileRef: map['mobile_ref'],
      status: map['status'],
    );
  }
}
