enum CrmActivityType {
  phoneCall,
  visit,
  meeting,
  message,
  note;

  String get label {
    return switch (this) {
      CrmActivityType.phoneCall => 'Ligacao',
      CrmActivityType.visit => 'Visita',
      CrmActivityType.meeting => 'Reuniao',
      CrmActivityType.message => 'Mensagem',
      CrmActivityType.note => 'Nota',
    };
  }

  String get analyticsCode {
    return switch (this) {
      CrmActivityType.phoneCall => 'phone_call',
      CrmActivityType.visit => 'visit',
      CrmActivityType.meeting => 'meeting',
      CrmActivityType.message => 'message',
      CrmActivityType.note => 'note',
    };
  }
}
