-- 群组服务数据库迁移脚本

-- 创建群组表
CREATE TABLE IF NOT EXISTS groups (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    name VARCHAR(50) NOT NULL,
    description TEXT,
    avatar_url VARCHAR(500),
    owner_id UUID NOT NULL,
    max_members INTEGER NOT NULL DEFAULT 100 CHECK (max_members >= 2 AND max_members <= 500),
    is_private BOOLEAN NOT NULL DEFAULT false,
    created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW()
);

-- 创建群组成员表
CREATE TABLE IF NOT EXISTS group_members (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    group_id UUID NOT NULL REFERENCES groups(id) ON DELETE CASCADE,
    user_id UUID NOT NULL,
    role VARCHAR(20) NOT NULL CHECK (role IN ('owner', 'admin', 'member')),
    status VARCHAR(20) NOT NULL DEFAULT 'active' CHECK (status IN ('active', 'muted', 'banned', 'pending')),
    joined_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW(),
    nickname VARCHAR(30),
    UNIQUE(group_id, user_id)
);

-- 创建群组邀请表
CREATE TABLE IF NOT EXISTS group_invitations (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    group_id UUID NOT NULL REFERENCES groups(id) ON DELETE CASCADE,
    inviter_id UUID NOT NULL,
    invitee_id UUID NOT NULL,
    status VARCHAR(20) NOT NULL DEFAULT 'pending' CHECK (status IN ('pending', 'accepted', 'rejected', 'expired')),
    message TEXT,
    created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW(),
    expires_at TIMESTAMP WITH TIME ZONE NOT NULL,
    UNIQUE(group_id, invitee_id, status) -- 防止重复邀请同一用户到同一群组
);

-- 创建索引以提高查询性能

-- 群组表索引
CREATE INDEX IF NOT EXISTS idx_groups_owner_id ON groups(owner_id);
CREATE INDEX IF NOT EXISTS idx_groups_name ON groups(name);
CREATE INDEX IF NOT EXISTS idx_groups_is_private ON groups(is_private);
CREATE INDEX IF NOT EXISTS idx_groups_created_at ON groups(created_at);

-- 群组成员表索引
CREATE INDEX IF NOT EXISTS idx_group_members_group_id ON group_members(group_id);
CREATE INDEX IF NOT EXISTS idx_group_members_user_id ON group_members(user_id);
CREATE INDEX IF NOT EXISTS idx_group_members_role ON group_members(role);
CREATE INDEX IF NOT EXISTS idx_group_members_status ON group_members(status);
CREATE INDEX IF NOT EXISTS idx_group_members_joined_at ON group_members(joined_at);

-- 群组邀请表索引
CREATE INDEX IF NOT EXISTS idx_group_invitations_group_id ON group_invitations(group_id);
CREATE INDEX IF NOT EXISTS idx_group_invitations_inviter_id ON group_invitations(inviter_id);
CREATE INDEX IF NOT EXISTS idx_group_invitations_invitee_id ON group_invitations(invitee_id);
CREATE INDEX IF NOT EXISTS idx_group_invitations_status ON group_invitations(status);
CREATE INDEX IF NOT EXISTS idx_group_invitations_expires_at ON group_invitations(expires_at);

-- 创建触发器以自动更新 updated_at 字段
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ language 'plpgsql';

-- 为群组表创建更新时间触发器
DROP TRIGGER IF EXISTS update_groups_updated_at ON groups;
CREATE TRIGGER update_groups_updated_at
    BEFORE UPDATE ON groups
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at_column();

-- 创建视图以简化常用查询

-- 群组成员统计视图
CREATE OR REPLACE VIEW group_member_stats AS
SELECT 
    g.id as group_id,
    g.name as group_name,
    g.owner_id,
    COUNT(gm.id) as total_members,
    COUNT(CASE WHEN gm.status = 'active' THEN 1 END) as active_members,
    COUNT(CASE WHEN gm.role = 'admin' THEN 1 END) as admin_count
FROM groups g
LEFT JOIN group_members gm ON g.id = gm.group_id
GROUP BY g.id, g.name, g.owner_id;

-- 用户群组参与视图
CREATE OR REPLACE VIEW user_group_participation AS
SELECT 
    gm.user_id,
    g.id as group_id,
    g.name as group_name,
    g.description,
    g.avatar_url,
    g.is_private,
    gm.role,
    gm.status,
    gm.joined_at,
    gm.nickname,
    (SELECT COUNT(*) FROM group_members WHERE group_id = g.id AND status = 'active') as member_count
FROM group_members gm
JOIN groups g ON gm.group_id = g.id
WHERE gm.status = 'active';

-- 待处理邀请视图
CREATE OR REPLACE VIEW pending_invitations_view AS
SELECT 
    gi.id as invitation_id,
    gi.group_id,
    g.name as group_name,
    g.description as group_description,
    g.avatar_url as group_avatar_url,
    gi.inviter_id,
    gi.invitee_id,
    gi.message,
    gi.created_at,
    gi.expires_at
FROM group_invitations gi
JOIN groups g ON gi.group_id = g.id
WHERE gi.status = 'pending' AND gi.expires_at > NOW();

-- 插入一些示例数据（可选，用于测试）
/*
-- 示例群组
INSERT INTO groups (id, name, description, owner_id, max_members, is_private) VALUES
('550e8400-e29b-41d4-a716-446655440001', '技术交流群', '讨论技术问题和分享经验', '550e8400-e29b-41d4-a716-446655440000', 100, false),
('550e8400-e29b-41d4-a716-446655440002', '项目团队', '项目开发团队内部沟通', '550e8400-e29b-41d4-a716-446655440000', 50, true);

-- 示例群组成员
INSERT INTO group_members (group_id, user_id, role, status) VALUES
('550e8400-e29b-41d4-a716-446655440001', '550e8400-e29b-41d4-a716-446655440000', 'owner', 'active'),
('550e8400-e29b-41d4-a716-446655440002', '550e8400-e29b-41d4-a716-446655440000', 'owner', 'active');
*/

-- 清理过期邀请的存储过程
CREATE OR REPLACE FUNCTION cleanup_expired_invitations()
RETURNS INTEGER AS $$
DECLARE
    affected_rows INTEGER;
BEGIN
    UPDATE group_invitations 
    SET status = 'expired' 
    WHERE status = 'pending' AND expires_at <= NOW();
    
    GET DIAGNOSTICS affected_rows = ROW_COUNT;
    RETURN affected_rows;
END;
$$ LANGUAGE plpgsql;

-- 获取群组统计信息的函数
CREATE OR REPLACE FUNCTION get_group_stats(group_uuid UUID)
RETURNS TABLE(
    total_members INTEGER,
    active_members INTEGER,
    admin_count INTEGER,
    owner_id UUID
) AS $$
BEGIN
    RETURN QUERY
    SELECT 
        COUNT(gm.id)::INTEGER as total_members,
        COUNT(CASE WHEN gm.status = 'active' THEN 1 END)::INTEGER as active_members,
        COUNT(CASE WHEN gm.role = 'admin' THEN 1 END)::INTEGER as admin_count,
        g.owner_id
    FROM groups g
    LEFT JOIN group_members gm ON g.id = gm.group_id
    WHERE g.id = group_uuid
    GROUP BY g.id, g.owner_id;
END;
$$ LANGUAGE plpgsql;