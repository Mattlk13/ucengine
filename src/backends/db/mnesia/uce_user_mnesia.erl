-module(uce_user_mnesia).

-author('victor.goya@af83.com').

-export([init/0, drop/0]).

-export([add/1,
	 delete/1,
	 update/1,
	 list/0,
	 get/1]).

-include("uce.hrl").

init() ->
    mnesia:create_table(uce_user,
			[{disc_copies, [node()]},
			 {type, set},
			 {attributes, record_info(fields, uce_user)}]).

add(#uce_user{} = User) ->
    case mnesia:transaction(fun() ->
			       mnesia:write(User)
		       end) of
	{atomic, _} ->
	    {ok, created};
	{aborted, Reason} ->
	    {error, Reason}
    end.

delete(EUid) ->
    case mnesia:transaction(fun() ->
				    mnesia:delete({uce_user, EUid})
			    end) of
	{atomic, ok} ->
	    {ok, deleted};
	{aborted, Reason} ->
	    {error, Reason}
    end.

update(#uce_user{} = User) ->
    case mnesia:transaction(fun() ->
			       mnesia:write(User)
		       end) of
	{atomic, _} ->
	    {ok, updated};
	{aborted, Reason} ->
	    {error, Reason}
    end.

list() ->
    {ok, ets:tab2list(uce_user)}.

get(EUid) ->
    case mnesia:transaction(fun() ->
				    mnesia:read(uce_user, EUid)
			    end) of
	{atomic, [Record]} ->
	    {ok, Record};
	{atomic, _} ->
	    {error, not_found};
	{aborted, Reason} ->
	    {error, Reason}
    end.

drop() ->
    mnesia:clear_table(uce_user).
