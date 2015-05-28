
class Status
  constructor: ->
    @connection = 'offline'
    @self =
      username: 'Unknown'
    @identitiesById = {}
    @conversations = []
    @conversationsById = {}
    @conversationCurrent = null
    @messagesByConversationId = {}

  # managing fns
  identityAdd: (id, name) ->
    object = id: id, name: name
    @identitiesById[id] = object
  conversationsSort: () ->
    timestampDesc = (a, b) -> a.ts > a.ts
    @conversations = @conversations.sort timestampDesc
  conversationAdd: (id, name, participants, ts) ->
    object = id: id, name: name, participants: participants, timestamp: ts
    @conversations.push object
    @conversationsSort()
    @conversationsById[id] = object
  messageAdd: (event) =>
    id = event.conversation_id.id
    if not @conversationCurrent then @conversationCurrent = id
    @conversationCurrent = id
    @messagesByConversationId[id] = @messagesByConversationId[id] || []
    @messagesByConversationId[id].push event

  # utils
  loadRecentConversations: (data) ->
    # extract conversations and partecipants
    data.conversation_state.forEach (conversation) =>
      conversation = conversation.conversation
      id = conversation.id.id
      sort_timestamp = conversation.self_conversation_state.sort_timestamp
      participants = []
      names = []
      conversation.participant_data.forEach (participant) =>
        @identityAdd participant.id.chat_id, participant.fallback_name
        participants.push participant.id.chat_id
        names.push participant.fallback_name
      name = names.join(", ")
      @conversationAdd id, name, participants, sort_timestamp
    # extract messages
    data.conversation_state.forEach (conversation) =>
      events = conversation.event
      for event in events
        if event.event_type == 'REGULAR_CHAT_MESSAGE'
          @messageAdd event
        else
          #console.log 'unhandled message type'
          #console.log JSON.stringify event, null, '  '
      

status = new Status()
status.test = -> console.log 'asf'

module.exports = status

if not module.parent
  onFile = (err, data) ->
    data = data.toString()
    data = JSON.parse data
    status.loadRecentConversations data
  fs = require 'fs'
  fs.readFile 'syncrecentconversations_response.json', onFile