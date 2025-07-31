-- Fix add member functionality by updating RLS policies
-- Run this script in your Supabase SQL Editor

-- Drop existing restrictive policies
DROP POLICY IF EXISTS "Users can add themselves to groups" ON public.group_memberships;
DROP POLICY IF EXISTS "Users can add themselves or admins can add members" ON public.group_memberships;
DROP POLICY IF EXISTS "Users can remove themselves from groups" ON public.group_memberships;

-- Create new policy that allows both self-joining and admin-managed additions
CREATE POLICY "Users can add themselves or admins can add members" ON public.group_memberships FOR INSERT 
WITH CHECK (
  user_id = auth.uid() OR 
  group_id IN (
    SELECT group_id FROM public.group_memberships 
    WHERE user_id = auth.uid() AND role = 'admin'
  )
);

-- Allow users to remove themselves or admins to remove members
CREATE POLICY "Users can remove themselves or admins can remove members" ON public.group_memberships FOR DELETE 
USING (
  user_id = auth.uid() OR 
  group_id IN (
    SELECT group_id FROM public.group_memberships 
    WHERE user_id = auth.uid() AND role = 'admin'
  )
);