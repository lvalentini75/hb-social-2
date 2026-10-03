-- HB Social 2.0 — Row Level Security Policies
-- Helper functions (SECURITY DEFINER) + RLS policies

-- ============================================================================
-- SECURITY DEFINER HELPER FUNCTIONS (no policy queries its own table)
-- ============================================================================

CREATE OR REPLACE FUNCTION is_group_member(group_id UUID, user_id UUID)
RETURNS BOOLEAN
LANGUAGE SQL
SECURITY DEFINER
SET search_path = public
STABLE AS $$
  SELECT EXISTS(
    SELECT 1 FROM group_members
    WHERE group_members.group_id = is_group_member.group_id
      AND group_members.user_id = is_group_member.user_id
  )
$$;

CREATE OR REPLACE FUNCTION is_group_manager(group_id UUID, user_id UUID)
RETURNS BOOLEAN
LANGUAGE SQL
SECURITY DEFINER
SET search_path = public
STABLE AS $$
  SELECT EXISTS(
    SELECT 1 FROM group_members
    WHERE group_members.group_id = is_group_manager.group_id
      AND group_members.user_id = is_group_manager.user_id
      AND group_members.role IN ('admin', 'manager')
  )
$$;

CREATE OR REPLACE FUNCTION is_conversation_participant(conversation_id UUID, user_id UUID)
RETURNS BOOLEAN
LANGUAGE SQL
SECURITY DEFINER
SET search_path = public
STABLE AS $$
  SELECT EXISTS(
    SELECT 1 FROM conversation_participants
    WHERE conversation_participants.conversation_id = is_conversation_participant.conversation_id
      AND conversation_participants.user_id = is_conversation_participant.user_id
  )
$$;

CREATE OR REPLACE FUNCTION is_event_participant(event_id UUID, user_id UUID)
RETURNS BOOLEAN
LANGUAGE SQL
SECURITY DEFINER
SET search_path = public
STABLE AS $$
  SELECT EXISTS(
    SELECT 1 FROM event_participants
    WHERE event_participants.event_id = is_event_participant.event_id
      AND event_participants.user_id = is_event_participant.user_id
  )
$$;

CREATE OR REPLACE FUNCTION is_admin(user_id UUID)
RETURNS BOOLEAN
LANGUAGE SQL
SECURITY DEFINER
SET search_path = public
STABLE AS $$
  SELECT EXISTS(
    SELECT 1 FROM admin_users
    WHERE admin_users.user_id = is_admin.user_id
  )
$$;

-- ============================================================================
-- RLS POLICIES FOR IDENTITY TABLES
-- ============================================================================

-- profiles: authenticated users can view all, update own
CREATE POLICY "Allow authenticated users to view profiles"
ON profiles FOR SELECT
USING (auth.role() = 'authenticated');

CREATE POLICY "Allow users to update own profile"
ON profiles FOR UPDATE
WITH CHECK (auth.uid() = id);

CREATE POLICY "Allow signup to create profile"
ON profiles FOR INSERT
WITH CHECK (true);

-- user_settings: users can view/update own
CREATE POLICY "Allow users to view own settings"
ON user_settings FOR SELECT
USING (auth.uid() = user_id);

CREATE POLICY "Allow users to update own settings"
ON user_settings FOR UPDATE
USING (auth.uid() = user_id)
WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Allow users to create own settings"
ON user_settings FOR INSERT
WITH CHECK (auth.uid() = user_id);

-- follows: authenticated users can view/manage own
CREATE POLICY "Allow authenticated to view follows"
ON follows FOR SELECT
USING (auth.role() = 'authenticated');

CREATE POLICY "Allow users to create follows"
ON follows FOR INSERT
WITH CHECK (auth.uid() = follower_id);

CREATE POLICY "Allow users to delete own follows"
ON follows FOR DELETE
USING (auth.uid() = follower_id);

-- blocks: authenticated users can view/manage own
CREATE POLICY "Allow authenticated to view blocks"
ON blocks FOR SELECT
USING (auth.role() = 'authenticated');

CREATE POLICY "Allow users to create blocks"
ON blocks FOR INSERT
WITH CHECK (auth.uid() = blocker_id);

CREATE POLICY "Allow users to delete own blocks"
ON blocks FOR DELETE
USING (auth.uid() = blocker_id);

-- notifications: users can view/manage own
CREATE POLICY "Allow users to view own notifications"
ON notifications FOR SELECT
USING (auth.uid() = user_id);

CREATE POLICY "Allow users to delete own notifications"
ON notifications FOR DELETE
USING (auth.uid() = user_id);

-- push_tokens: users can manage own
CREATE POLICY "Allow users to view own tokens"
ON push_tokens FOR SELECT
USING (auth.uid() = user_id);

CREATE POLICY "Allow users to create tokens"
ON push_tokens FOR INSERT
WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Allow users to delete own tokens"
ON push_tokens FOR DELETE
USING (auth.uid() = user_id);

-- ============================================================================
-- RLS POLICIES FOR CONTENT TABLES
-- ============================================================================

-- posts: authenticated can view all, create own, update/delete own
CREATE POLICY "Allow authenticated to view posts"
ON posts FOR SELECT
USING (auth.role() = 'authenticated');

CREATE POLICY "Allow users to create posts"
ON posts FOR INSERT
WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Allow users to update own posts"
ON posts FOR UPDATE
USING (auth.uid() = user_id)
WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Allow users to delete own posts"
ON posts FOR DELETE
USING (auth.uid() = user_id);

-- post_media: inherited from posts
CREATE POLICY "Allow authenticated to view post media"
ON post_media FOR SELECT
USING (auth.role() = 'authenticated');

CREATE POLICY "Allow users to create media for own posts"
ON post_media FOR INSERT
WITH CHECK (auth.uid() = (SELECT user_id FROM posts WHERE id = post_id));

-- reactions: authenticated can view all, create own, delete own
CREATE POLICY "Allow authenticated to view reactions"
ON reactions FOR SELECT
USING (auth.role() = 'authenticated');

CREATE POLICY "Allow users to create reactions"
ON reactions FOR INSERT
WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Allow users to delete own reactions"
ON reactions FOR DELETE
USING (auth.uid() = user_id);

-- comments: authenticated can view all, create own, update/delete own
CREATE POLICY "Allow authenticated to view comments"
ON comments FOR SELECT
USING (auth.role() = 'authenticated');

CREATE POLICY "Allow users to create comments"
ON comments FOR INSERT
WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Allow users to update own comments"
ON comments FOR UPDATE
USING (auth.uid() = user_id)
WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Allow users to delete own comments"
ON comments FOR DELETE
USING (auth.uid() = user_id);

-- stories: authenticated can view all, create own, delete own
CREATE POLICY "Allow authenticated to view stories"
ON stories FOR SELECT
USING (auth.role() = 'authenticated');

CREATE POLICY "Allow users to create stories"
ON stories FOR INSERT
WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Allow users to delete own stories"
ON stories FOR DELETE
USING (auth.uid() = user_id);

-- ============================================================================
-- RLS POLICIES FOR COMMUNITY TABLES
-- ============================================================================

-- groups: authenticated can view public, members can view own
CREATE POLICY "Allow authenticated to view groups"
ON groups FOR SELECT
USING (auth.role() = 'authenticated' AND (is_public OR auth.uid() = created_by_id OR is_group_member(id, auth.uid())));

CREATE POLICY "Allow users to create groups"
ON groups FOR INSERT
WITH CHECK (auth.uid() = created_by_id);

CREATE POLICY "Allow group managers to update groups"
ON groups FOR UPDATE
USING (auth.uid() = created_by_id OR is_group_manager(id, auth.uid()))
WITH CHECK (auth.uid() = created_by_id OR is_group_manager(id, auth.uid()));

-- group_members: members can view, authenticated can join
CREATE POLICY "Allow members to view group members"
ON group_members FOR SELECT
USING (auth.role() = 'authenticated');

CREATE POLICY "Allow users to join groups"
ON group_members FOR INSERT
WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Allow managers to manage members"
ON group_members FOR UPDATE
USING (is_group_manager(group_id, auth.uid()))
WITH CHECK (is_group_manager(group_id, auth.uid()));

CREATE POLICY "Allow users to leave groups"
ON group_members FOR DELETE
USING (auth.uid() = user_id OR is_group_manager(group_id, auth.uid()));

-- pages: authenticated can view public
CREATE POLICY "Allow authenticated to view pages"
ON pages FOR SELECT
USING (auth.role() = 'authenticated');

CREATE POLICY "Allow users to create pages"
ON pages FOR INSERT
WITH CHECK (auth.uid() = created_by_id);

CREATE POLICY "Allow page creators to update pages"
ON pages FOR UPDATE
USING (auth.uid() = created_by_id)
WITH CHECK (auth.uid() = created_by_id);

-- page_followers: authenticated can follow, manage own follows
CREATE POLICY "Allow authenticated to view followers"
ON page_followers FOR SELECT
USING (auth.role() = 'authenticated');

CREATE POLICY "Allow users to follow pages"
ON page_followers FOR INSERT
WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Allow users to unfollow pages"
ON page_followers FOR DELETE
USING (auth.uid() = user_id);

-- forums: authenticated can view
CREATE POLICY "Allow authenticated to view forums"
ON forums FOR SELECT
USING (auth.role() = 'authenticated');

CREATE POLICY "Allow users to create forums"
ON forums FOR INSERT
WITH CHECK (auth.uid() = created_by_id);

-- forum_threads: authenticated can view
CREATE POLICY "Allow authenticated to view threads"
ON forum_threads FOR SELECT
USING (auth.role() = 'authenticated');

CREATE POLICY "Allow users to create threads"
ON forum_threads FOR INSERT
WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Allow users to update own threads"
ON forum_threads FOR UPDATE
USING (auth.uid() = user_id)
WITH CHECK (auth.uid() = user_id);

-- forum_replies: authenticated can view
CREATE POLICY "Allow authenticated to view replies"
ON forum_replies FOR SELECT
USING (auth.role() = 'authenticated');

CREATE POLICY "Allow users to create replies"
ON forum_replies FOR INSERT
WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Allow users to update own replies"
ON forum_replies FOR UPDATE
USING (auth.uid() = user_id)
WITH CHECK (auth.uid() = user_id);

-- events: authenticated can view
CREATE POLICY "Allow authenticated to view events"
ON events FOR SELECT
USING (auth.role() = 'authenticated');

CREATE POLICY "Allow users to create events"
ON events FOR INSERT
WITH CHECK (auth.uid() = created_by_id);

CREATE POLICY "Allow event creators to update events"
ON events FOR UPDATE
USING (auth.uid() = created_by_id)
WITH CHECK (auth.uid() = created_by_id);

-- event_participants: authenticated can view, manage own participation
CREATE POLICY "Allow authenticated to view participants"
ON event_participants FOR SELECT
USING (auth.role() = 'authenticated');

CREATE POLICY "Allow users to join events"
ON event_participants FOR INSERT
WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Allow users to update own participation"
ON event_participants FOR UPDATE
USING (auth.uid() = user_id)
WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Allow users to leave events"
ON event_participants FOR DELETE
USING (auth.uid() = user_id);

-- ============================================================================
-- RLS POLICIES FOR COMMERCE TABLES
-- ============================================================================

-- categories: authenticated can view
CREATE POLICY "Allow authenticated to view categories"
ON categories FOR SELECT
USING (auth.role() = 'authenticated');

-- listings: authenticated can view all, create own, update/delete own
CREATE POLICY "Allow authenticated to view listings"
ON listings FOR SELECT
USING (auth.role() = 'authenticated');

CREATE POLICY "Allow users to create listings"
ON listings FOR INSERT
WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Allow users to update own listings"
ON listings FOR UPDATE
USING (auth.uid() = user_id)
WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Allow users to delete own listings"
ON listings FOR DELETE
USING (auth.uid() = user_id);

-- listing_media: inherited from listings
CREATE POLICY "Allow authenticated to view listing media"
ON listing_media FOR SELECT
USING (auth.role() = 'authenticated');

CREATE POLICY "Allow users to add media to own listings"
ON listing_media FOR INSERT
WITH CHECK (auth.uid() = (SELECT user_id FROM listings WHERE id = listing_id));

-- ============================================================================
-- RLS POLICIES FOR CHAT TABLES
-- ============================================================================

-- conversations: participants only
CREATE POLICY "Allow participants to view conversations"
ON conversations FOR SELECT
USING (auth.role() = 'authenticated' AND is_conversation_participant(id, auth.uid()));

CREATE POLICY "Allow users to create conversations"
ON conversations FOR INSERT
WITH CHECK (auth.role() = 'authenticated');

-- conversation_participants: authenticated can view, manage own
CREATE POLICY "Allow authenticated to view conversation participants"
ON conversation_participants FOR SELECT
USING (auth.role() = 'authenticated');

CREATE POLICY "Allow users to join conversations"
ON conversation_participants FOR INSERT
WITH CHECK (auth.uid() = user_id);

-- messages: participants only
CREATE POLICY "Allow participants to view messages"
ON messages FOR SELECT
USING (auth.role() = 'authenticated' AND is_conversation_participant(conversation_id, auth.uid()));

CREATE POLICY "Allow users to create messages"
ON messages FOR INSERT
WITH CHECK (auth.uid() = user_id);

-- ============================================================================
-- RLS POLICIES FOR HUNTING TABLES
-- ============================================================================

-- hunting_countries: authenticated can view
CREATE POLICY "Allow authenticated to view hunting countries"
ON hunting_countries FOR SELECT
USING (auth.role() = 'authenticated');

-- hunting_regions: authenticated can view
CREATE POLICY "Allow authenticated to view hunting regions"
ON hunting_regions FOR SELECT
USING (auth.role() = 'authenticated');

-- hunting_units: authenticated can view
CREATE POLICY "Allow authenticated to view hunting units"
ON hunting_units FOR SELECT
USING (auth.role() = 'authenticated');

-- species: authenticated can view
CREATE POLICY "Allow authenticated to view species"
ON species FOR SELECT
USING (auth.role() = 'authenticated');

-- species_names: authenticated can view
CREATE POLICY "Allow authenticated to view species names"
ON species_names FOR SELECT
USING (auth.role() = 'authenticated');

-- hunting_calendars: authenticated can view
CREATE POLICY "Allow authenticated to view hunting calendars"
ON hunting_calendars FOR SELECT
USING (auth.role() = 'authenticated');

-- calendar_rules: authenticated can view
CREATE POLICY "Allow authenticated to view calendar rules"
ON calendar_rules FOR SELECT
USING (auth.role() = 'authenticated');

-- hunting_logs: authenticated can view all, create/update/delete own
CREATE POLICY "Allow authenticated to view hunting logs"
ON hunting_logs FOR SELECT
USING (auth.role() = 'authenticated');

CREATE POLICY "Allow users to create hunting logs"
ON hunting_logs FOR INSERT
WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Allow users to update own hunting logs"
ON hunting_logs FOR UPDATE
USING (auth.uid() = user_id)
WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Allow users to delete own hunting logs"
ON hunting_logs FOR DELETE
USING (auth.uid() = user_id);

-- dogs: authenticated can view all, create/update/delete own
CREATE POLICY "Allow authenticated to view dogs"
ON dogs FOR SELECT
USING (auth.role() = 'authenticated');

CREATE POLICY "Allow users to create dogs"
ON dogs FOR INSERT
WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Allow users to update own dogs"
ON dogs FOR UPDATE
USING (auth.uid() = user_id)
WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Allow users to delete own dogs"
ON dogs FOR DELETE
USING (auth.uid() = user_id);

-- ============================================================================
-- RLS POLICIES FOR I18N TABLES
-- ============================================================================

-- currencies: authenticated can view
CREATE POLICY "Allow authenticated to view currencies"
ON currencies FOR SELECT
USING (auth.role() = 'authenticated');

-- exchange_rates: authenticated can view
CREATE POLICY "Allow authenticated to view exchange rates"
ON exchange_rates FOR SELECT
USING (auth.role() = 'authenticated');

-- feature_flags: authenticated can view
CREATE POLICY "Allow authenticated to view feature flags"
ON feature_flags FOR SELECT
USING (auth.role() = 'authenticated');

-- country_policies: authenticated can view
CREATE POLICY "Allow authenticated to view country policies"
ON country_policies FOR SELECT
USING (auth.role() = 'authenticated');

-- ============================================================================
-- RLS POLICIES FOR ADMIN TABLES
-- ============================================================================

-- admin_roles: admins only
CREATE POLICY "Allow admins to view roles"
ON admin_roles FOR SELECT
USING (auth.role() = 'authenticated' AND is_admin(auth.uid()));

-- admin_users: admins only
CREATE POLICY "Allow admins to view admin users"
ON admin_users FOR SELECT
USING (auth.role() = 'authenticated' AND is_admin(auth.uid()));

-- admin_audit_log: admins only
CREATE POLICY "Allow admins to view audit log"
ON admin_audit_log FOR SELECT
USING (auth.role() = 'authenticated' AND is_admin(auth.uid()));

CREATE POLICY "Allow system to create audit log"
ON admin_audit_log FOR INSERT
WITH CHECK (auth.role() = 'authenticated');
