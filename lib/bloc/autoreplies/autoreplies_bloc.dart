import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import '../../models/models.dart';
import '../../services/api_service.dart';

part 'autoreplies_event.dart';
part 'autoreplies_state.dart';

class AutoRepliesBloc extends Bloc<AutoRepliesEvent, AutoRepliesState> {
  final ApiService _api;

  AutoRepliesBloc({required ApiService api})
      : _api = api,
        super(const AutoRepliesInitial()) {
    on<LoadAutoRepliesEvent>(_onLoad);
    on<AddAutoReplyEvent>(_onAdd);
    on<DeleteAutoReplyEvent>(_onDelete);
  }

  Future<void> _onLoad(LoadAutoRepliesEvent e, Emitter<AutoRepliesState> emit) async {
    emit(const AutoRepliesLoading());
    try {
      final res  = await _api.getAutoReplies();
      final list = (res.data as List).map((j) => AutoReply.fromJson(j)).toList();
      emit(AutoRepliesLoaded(list));
    } catch (_) {
      emit(const AutoRepliesError('Failed to load auto-replies'));
    }
  }

  Future<void> _onAdd(AddAutoReplyEvent e, Emitter<AutoRepliesState> emit) async {
    try {
      await _api.createAutoReply({
        'trigger_type':  e.type,
        'trigger_value': e.trigger,
        'response':      e.response,
      });
      add(const LoadAutoRepliesEvent());
    } catch (_) {
      emit(const AutoRepliesError('Failed to add rule'));
    }
  }

  Future<void> _onDelete(DeleteAutoReplyEvent e, Emitter<AutoRepliesState> emit) async {
    try {
      await _api.deleteAutoReply(e.id);
      add(const LoadAutoRepliesEvent());
    } catch (_) {
      emit(const AutoRepliesError('Failed to delete rule'));
    }
  }
}