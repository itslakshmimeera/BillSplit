-- Restore proper RLS policies after testing
-- Drop the temporary open policies
DROP POLICY IF EXISTS "enable_all_for_groups" ON public.groups;
DROP POLICY IF EXISTS "enable_all_for_memberships" ON public.group_memberships;
DROP POLICY IF EXISTS "enable_all_for_expenses" ON public.expenses;
DROP POLICY IF EXISTS "enable_all_for_expense_splits" ON public.expense_splits;
DROP POLICY IF EXISTS "enable_all_for_settlements" ON public.settlements;

-- Create proper RLS policies for groups
CREATE POLICY "Users can view groups they created or belong to" ON public.groups FOR SELECT 
USING (
  created_by = auth.uid() OR 
  id IN (
    SELECT group_id FROM public.group_memberships 
    WHERE user_id = auth.uid()
  )
);

CREATE POLICY "Users can create groups" ON public.groups FOR INSERT 
WITH CHECK (auth.uid() = created_by);

CREATE POLICY "Group creators can update their groups" ON public.groups FOR UPDATE 
USING (created_by = auth.uid());

CREATE POLICY "Group creators can delete their groups" ON public.groups FOR DELETE 
USING (created_by = auth.uid());

-- Create proper RLS policies for group_memberships
CREATE POLICY "Users can view memberships for groups they belong to" ON public.group_memberships FOR SELECT 
USING (
  group_id IN (
    SELECT group_id FROM public.group_memberships 
    WHERE user_id = auth.uid()
  )
);

-- Allow users to add themselves OR group admins to add others
CREATE POLICY "Users can add themselves or admins can add members" ON public.group_memberships FOR INSERT 
WITH CHECK (
  user_id = auth.uid() OR 
  group_id IN (
    SELECT group_id FROM public.group_memberships 
    WHERE user_id = auth.uid() AND role = 'admin'
  )
);

CREATE POLICY "Users can update their own memberships" ON public.group_memberships FOR UPDATE 
USING (user_id = auth.uid());

CREATE POLICY "Users can remove themselves from groups" ON public.group_memberships FOR DELETE 
USING (user_id = auth.uid());

-- Create proper RLS policies for expenses
CREATE POLICY "Users can view expenses for groups they belong to" ON public.expenses FOR SELECT 
USING (
  group_id IN (
    SELECT group_id FROM public.group_memberships 
    WHERE user_id = auth.uid()
  )
);

CREATE POLICY "Group members can create expenses" ON public.expenses FOR INSERT 
WITH CHECK (
  group_id IN (
    SELECT group_id FROM public.group_memberships 
    WHERE user_id = auth.uid()
  ) AND auth.uid() = paid_by
);

CREATE POLICY "Expense creators can update their expenses" ON public.expenses FOR UPDATE 
USING (auth.uid() = paid_by);

CREATE POLICY "Expense creators can delete their expenses" ON public.expenses FOR DELETE 
USING (auth.uid() = paid_by);

-- Create proper RLS policies for expense_splits
CREATE POLICY "Users can view splits for expenses in their groups" ON public.expense_splits FOR SELECT 
USING (
  expense_id IN (
    SELECT id FROM public.expenses 
    WHERE group_id IN (
      SELECT group_id FROM public.group_memberships 
      WHERE user_id = auth.uid()
    )
  )
);

CREATE POLICY "Expense creators can manage splits" ON public.expense_splits FOR ALL 
USING (
  expense_id IN (
    SELECT id FROM public.expenses 
    WHERE paid_by = auth.uid()
  )
);

-- Create proper RLS policies for settlements
CREATE POLICY "Users can view settlements for their groups" ON public.settlements FOR SELECT 
USING (
  group_id IN (
    SELECT group_id FROM public.group_memberships 
    WHERE user_id = auth.uid()
  )
);

CREATE POLICY "Users can create settlements" ON public.settlements FOR INSERT 
WITH CHECK (
  group_id IN (
    SELECT group_id FROM public.group_memberships 
    WHERE user_id = auth.uid()
  )
);

CREATE POLICY "Users can update their settlements" ON public.settlements FOR UPDATE 
USING (auth.uid() = from_user OR auth.uid() = to_user); 