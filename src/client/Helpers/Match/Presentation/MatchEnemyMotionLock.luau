local EnemyMotionLock = {}

local OWNER_PRIORITY = {
	Idle = 10,
	Shadow = 20,
	Recovery = 40,
	DefensiveLine = 50,
	Zone3Blocker = 60,
	PassPress = 70,
	Approach = 80,
	Frozen = 90,
	PostShot = 100,
}

local function getPriority(owner: string?): number
	return OWNER_PRIORITY[tostring(owner or "")] or 0
end

function EnemyMotionLock.Attach(controller)
	if not controller or controller._enemyMotionLockAttached then
		return
	end

	controller._enemyMotionLockAttached = true
	controller.EnemyMotionLocks = controller.EnemyMotionLocks or {}

	function controller:_ensureEnemyMotionLocks()
		self.EnemyMotionLocks = self.EnemyMotionLocks or {}
		return self.EnemyMotionLocks
	end

	function controller:_resetEnemyMotionLocks()
		local locks = self:_ensureEnemyMotionLocks()
		table.clear(locks)
	end

	function controller:_getEnemyMotionOwner(enemyModel)
		if not enemyModel then
			return nil
		end

		local locks = self:_ensureEnemyMotionLocks()
		local lock = locks[enemyModel]
		return lock and lock.Owner or nil
	end

	function controller:_acquireEnemyMotionLock(enemyModel, owner: string, options)
		if not enemyModel then
			return false
		end

		local locks = self:_ensureEnemyMotionLocks()
		local existing = locks[enemyModel]
		local force = options and options.Force == true
		local ownerPriority = getPriority(owner)

		if existing and existing.Owner ~= owner and not force then
			local existingPriority = getPriority(existing.Owner)
			if existingPriority > ownerPriority then
				return false
			end
		end

		locks[enemyModel] = {
			Owner = owner,
			StartedAt = os.clock(),
		}

		return true
	end

	function controller:_releaseEnemyMotionLock(enemyModel, owner: string?)
		if not enemyModel then
			return
		end

		local locks = self:_ensureEnemyMotionLocks()
		local existing = locks[enemyModel]
		if not existing then
			return
		end

		if owner ~= nil and existing.Owner ~= owner then
			return
		end

		locks[enemyModel] = nil
	end

	function controller:_isEnemyMotionLockedByOther(enemyModel, owner: string): boolean
		if not enemyModel then
			return false
		end

		local locks = self:_ensureEnemyMotionLocks()
		local existing = locks[enemyModel]
		return existing ~= nil and existing.Owner ~= owner
	end
end

return EnemyMotionLock
