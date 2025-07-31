-- Fix add member functionality by updating RLS policy
-- Drop the restrictive policy that only allows self-joining
DROP POLICY IF EXISTS "Users can add themselves to groups" ON public.group_memberships;

-- Create new policy that allows both self-joining and admin-managed additions
CREATE POLICY "Users can add themselves or admins can add members" ON public.group_memberships FOR INSERT 
WITH CHECK (
  user_id = auth.uid() OR 
  group_id IN (
    SELECT group_id FROM public.group_memberships 
    WHERE user_id = auth.uid() AND role = 'admin'
  )
);