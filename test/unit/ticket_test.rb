# encoding: utf-8
require 'test_helper'

class TicketTest < ActiveSupport::TestCase
  test 'ticket create' do
    ticket = Ticket.create(
      title: "some title\n äöüß",
      group: Group.lookup( name: 'Users'),
      customer_id: 2,
      state: Ticket::State.lookup( name: 'new' ),
      priority: Ticket::Priority.lookup( name: '2 normal' ),
      updated_by_id: 1,
      created_by_id: 1,
    )
    assert( ticket, 'ticket created' )

    assert_equal( ticket.title, 'some title  äöüß', 'ticket.title verify' )
    assert_equal( ticket.group.name, 'Users', 'ticket.group verify' )
    assert_equal( ticket.state.name, 'new', 'ticket.state verify' )

    # create inbound article
    article_inbound = Ticket::Article.create(
      ticket_id: ticket.id,
      from: 'some_sender@example.com',
      to: 'some_recipient@example.com',
      subject: 'some subject',
      message_id: 'some@id',
      body: 'some message article_inbound 😍😍😍',
      internal: false,
      sender: Ticket::Article::Sender.where(name: 'Customer').first,
      type: Ticket::Article::Type.where(name: 'email').first,
      updated_by_id: 1,
      created_by_id: 1,
    )
    assert_equal( article_inbound.body, 'some message article_inbound 😍😍😍'.utf8_to_3bytesutf8, 'article_inbound.body verify - inbound' )

    ticket = Ticket.find(ticket.id)
    assert_equal( ticket.article_count, 1, 'ticket.article_count verify - inbound' )
    assert_equal( ticket.last_contact.to_s, article_inbound.created_at.to_s, 'ticket.last_contact verify - inbound' )
    assert_equal( ticket.last_contact_customer.to_s, article_inbound.created_at.to_s, 'ticket.last_contact_customer verify - inbound' )
    assert_equal( ticket.last_contact_agent, nil, 'ticket.last_contact_agent verify - inbound' )
    assert_equal( ticket.first_response, nil, 'ticket.first_response verify - inbound' )
    assert_equal( ticket.close_time, nil, 'ticket.close_time verify - inbound' )

    # create note article
    article_note = Ticket::Article.create(
      ticket_id: ticket.id,
      from: 'some person',
      subject: "some\nnote",
      body: "some\n message",
      internal: true,
      sender: Ticket::Article::Sender.where(name: 'Agent').first,
      type: Ticket::Article::Type.where(name: 'note').first,
      updated_by_id: 1,
      created_by_id: 1,
    )
    assert_equal( article_note.subject, 'some note', 'article_note.subject verify - inbound' )
    assert_equal( article_note.body, "some\n message", 'article_note.body verify - inbound' )

    ticket = Ticket.find(ticket.id)
    assert_equal( ticket.article_count, 2, 'ticket.article_count verify - note' )
    assert_equal( ticket.last_contact.to_s, article_inbound.created_at.to_s, 'ticket.last_contact verify - note' )
    assert_equal( ticket.last_contact_customer.to_s, article_inbound.created_at.to_s, 'ticket.last_contact_customer verify - note' )
    assert_equal( ticket.last_contact_agent, nil, 'ticket.last_contact_agent verify - note' )
    assert_equal( ticket.first_response, nil, 'ticket.first_response verify - note' )
    assert_equal( ticket.close_time, nil, 'ticket.close_time verify - note' )

    # create outbound article
    sleep 10
    article_outbound = Ticket::Article.create(
      ticket_id: ticket.id,
      from: 'some_recipient@example.com',
      to: 'some_sender@example.com',
      subject: 'some subject',
      message_id: 'some@id2',
      body: 'some message 2',
      internal: false,
      sender: Ticket::Article::Sender.where(name: 'Agent').first,
      type: Ticket::Article::Type.where(name: 'email').first,
      updated_by_id: 1,
      created_by_id: 1,
    )

    ticket = Ticket.find(ticket.id)
    assert_equal( ticket.article_count, 3, 'ticket.article_count verify - outbound' )
    assert_equal( ticket.last_contact.to_s, article_outbound.created_at.to_s, 'ticket.last_contact verify - outbound' )
    assert_equal( ticket.last_contact_customer.to_s, article_inbound.created_at.to_s, 'ticket.last_contact_customer verify - outbound' )
    assert_equal( ticket.last_contact_agent.to_s, article_outbound.created_at.to_s, 'ticket.last_contact_agent verify - outbound' )
    assert_equal( ticket.first_response.to_s, article_outbound.created_at.to_s, 'ticket.first_response verify - outbound' )
    assert_equal( ticket.close_time, nil, 'ticket.close_time verify - outbound' )

    ticket.state_id = Ticket::State.where(name: 'closed').first.id
    ticket.save

    ticket = Ticket.find(ticket.id)
    assert_equal( ticket.article_count, 3, 'ticket.article_count verify - state update' )
    assert_equal( ticket.last_contact.to_s, article_outbound.created_at.to_s, 'ticket.last_contact verify - state update' )
    assert_equal( ticket.last_contact_customer.to_s, article_inbound.created_at.to_s, 'ticket.last_contact_customer verify - state update' )
    assert_equal( ticket.last_contact_agent.to_s, article_outbound.created_at.to_s, 'ticket.last_contact_agent verify - state update' )
    assert_equal( ticket.first_response.to_s, article_outbound.created_at.to_s, 'ticket.first_response verify - state update' )
    assert( ticket.close_time, 'ticket.close_time verify - state update' )

    # set pending time
    ticket.state_id     = Ticket::State.where(name: 'pending reminder').first.id
    ticket.pending_time = Time.parse('1977-10-27 22:00:00 +0000')
    ticket.save

    ticket = Ticket.find(ticket.id)
    assert_equal( ticket.state.name, 'pending reminder', 'state verify' )
    assert_equal( ticket.pending_time, Time.parse('1977-10-27 22:00:00 +0000'), 'pending_time verify' )

    # reset pending state, should also reset pending time
    ticket.state_id = Ticket::State.where(name: 'closed').first.id
    ticket.save

    ticket = Ticket.find(ticket.id)
    assert_equal( ticket.state.name, 'closed', 'state verify' )
    assert_equal( ticket.pending_time, nil )

    delete = ticket.destroy
    assert( delete, 'ticket destroy' )
  end

  test 'ticket latest change' do
    ticket1 = Ticket.create(
      title: 'latest change 1',
      group: Group.lookup( name: 'Users'),
      customer_id: 2,
      state: Ticket::State.lookup( name: 'new' ),
      priority: Ticket::Priority.lookup( name: '2 normal' ),
      updated_by_id: 1,
      created_by_id: 1,
    )
    assert_equal( Ticket.latest_change.to_s, ticket1.updated_at.to_s )

    sleep 1

    ticket2 = Ticket.create(
      title: 'latest change 2',
      group: Group.lookup( name: 'Users'),
      customer_id: 2,
      state: Ticket::State.lookup( name: 'new' ),
      priority: Ticket::Priority.lookup( name: '2 normal' ),
      updated_by_id: 1,
      created_by_id: 1,
    )
    assert_equal( Ticket.latest_change.to_s, ticket2.updated_at.to_s )

    sleep 1

    ticket1.title = 'latest change 1 - 1'
    ticket1.save
    assert_equal( Ticket.latest_change.to_s, ticket1.updated_at.to_s )

    sleep 1

    ticket1.touch
    assert_equal( Ticket.latest_change.to_s, ticket1.updated_at.to_s )

    ticket1.destroy
    assert_equal( Ticket.latest_change.to_s, ticket2.updated_at.to_s )

  end
end
