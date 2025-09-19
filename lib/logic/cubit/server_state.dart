part of 'server_cubit.dart';

abstract class ServerState {}

class ServerInitial extends ServerState {}

class ServerLoading extends ServerState {}

class ServerConnected extends ServerState {}

class ServerDisconnected extends ServerState {}
