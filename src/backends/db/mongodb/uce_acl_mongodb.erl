%%
%%  U.C.Engine - Unified Colloboration Engine
%%  Copyright (C) 2011 af83
%%
%%  This program is free software: you can redistribute it and/or modify
%%  it under the terms of the GNU Affero General Public License as published by
%%  the Free Software Foundation, either version 3 of the License, or
%%  (at your option) any later version.
%%
%%  This program is distributed in the hope that it will be useful,
%%  but WITHOUT ANY WARRANTY; without even the implied warranty of
%%  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
%%  GNU Affero General Public License for more details.
%%
%%  You should have received a copy of the GNU Affero General Public License
%%  along with this program.  If not, see <http://www.gnu.org/licenses/>.
%%
-module(uce_acl_mongodb).

-author('victor.goya@af83.com').

-behaviour(gen_uce_acl).

-export([add/2,
         delete/6,
         list/4]).

-include("uce.hrl").
-include("mongodb.hrl").

add(_Domain, #uce_acl{}=ACL) ->
    case catch emongo:insert_sync(?MONGO_POOL, "uce_acl", to_collection(ACL)) of
	{'EXIT', _} ->
	    {error, bad_parameters};
	_ ->
	    {ok, created}
    end.

delete(Domain, Uid, Object, Action, Location, Conditions) ->
    case exists(Domain, Uid, Object, Action, Location, Conditions) of
	false ->
	    {error, not_found};
	true ->
	    case catch emongo:delete(?MONGO_POOL, "uce_acl", [{"uid", Uid},
							      {"object", Object},
							      {"action", Action},
							      {"location", Location},
							      {"conditions", Conditions}]) of
		{'EXIT', _} ->
		    {error, bad_parameters};
		_ ->
		    {ok, deleted}
	    end
    end.

list(Domain, Uid, Object, Action) ->
    case catch emongo:find_all(?MONGO_POOL, "uce_acl", [{"uid", Uid},
                                                        {"object", Object},
                                                        {"action", Action}]) of
	
	{'EXIT', _} ->
	    {error, bad_parameters};
	ACLCollections ->
	    ACL = lists:map(fun(Collection) ->
				    from_collection(Collection)
			    end,
			    ACLCollections),
	    {ok, AllActions} =
		case Action of
		    "all" ->
			{ok, []};
		    _ ->
			?MODULE:list(Domain, Uid, Object, "all")
		end,
	    {ok, AllObjects} =
		case Object of
		    "all" ->
			{ok, []};
		    _ ->
			?MODULE:list(Domain, Uid, "all", Action)
		end,
	    {ok, ACL ++ AllActions ++ AllObjects}
    end.

from_collection(Collection) ->
    case utils:get(mongodb_helpers:collection_to_list(Collection),
		   ["uid", "object", "action", "location", "conditions"]) of
	[Uid, Object, Action, Location, Conditions] ->
	    #uce_acl{uid=Uid,
		     action=Action,
		     object=Object,
		     location=Location,
		     conditions=Conditions};
	_ ->
	    {error, bad_parameters}
    end.
						      
to_collection(#uce_acl{uid=Uid,
		       object=Object,
		       action=Action,
		       location=Location,
		       conditions=Conditions}) ->
    [{"uid", Uid},
     {"object", Object},
     {"action", Action},
     {"location", Location},
     {"conditions", Conditions}].

exists(_Domain, Uid, Object, Action, Location, Conditions) ->
    case catch emongo:find_all(?MONGO_POOL, "uce_acl", [{"uid", Uid},
                                                        {"object", Object},
                                                        {"action", Action},
                                                        {"location", Location},
                                                        {"conditions", Conditions}],
			  [{limit, 1}]) of
	{'EXIT', _} ->
	    false;
	[] ->
	    false;
	_ ->
	    true
    end.
